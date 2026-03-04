#!/usr/bin/env bash

# ==============================================================================
# buildKernel.sh – YACKS (yet another compile kernel script)
# ==============================================================================

set -euo pipefail

DEBUG=0
VERBOSITY=0
REV=

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_CONFIG="${SCRIPT_DIR}/kernel_config.sh"
KERNEL_SRC_DIR="linux"
BUILD_LOG_FILE="kernelBuild.log"
LOCALVERSION="$(whoami)-$(hostname -s)${REV:+-$REV}"

ARCH="$(uname -m)"
export ARCH
export CCACHE_DIR="./ccache_kernel"  # separater Cache vom normalen ccache
export CCACHE_MAXSIZE="10G"
export CC="ccache gcc"
export CXX="ccache g++"
export LD=ld.bfd
# shfmt-ignore
export N_PROC=$(($(nproc) + 4)) # default: +4; you should configure a maximum of 1.5x CPU cores for faster builds on I/O bound systems

# --- Helpers -----------------------------------------------------------------
info() { printf "[*] %s\n" "$@"; }
warn() { printf "[!] %s\n" "$@"; }
debug() {
  [[ $DEBUG -eq 0 ]] && return 0
  VERBOSITY=1
  printf "[D] %s\n" "$@"
}
success() { printf "[+] %s\n" "$@"; }
die() {
  printf "ERROR: %s\n" "$@" >&2
  exit 1
}

# --- Sanity checks -----------------------------------------------------------
info "Current kernel: $(uname -r)"
debug "Script directory: $SCRIPT_DIR"
cd "$KERNEL_SRC_DIR" 2> /dev/null ||
  die "Kernel source directory '$KERNEL_SRC_DIR' not found. Did you clone the kernel sources?"

# --- Verify GCC --------------------------------------------------------------
if ! command -v gcc &> /dev/null; then
  die "GCC not found."
fi
GCC_MAJOR=$(gcc -dumpversion | cut -d. -f1)
info "Using GCC ${GCC_MAJOR}"
[[ "$GCC_MAJOR" -lt 13 ]] && die "GCC 13+ required for znver4, found GCC ${GCC_MAJOR}"

# --- Clean & reset git -------------------------------------------------------
info "Cleanup and checkout..."
make CC=gcc distclean || die "make distclean failed – is this a valid kernel source tree?"
git reset --hard && git clean -dfx  # NOTE: change if patches once introduced

# --- Determine kernel version from git tag -----------------------------------
KERNEL_VERSION_DIR=$(git tag --merged HEAD --sort=version:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | tail -n1)
debug "Latest merged version tag: $KERNEL_VERSION_DIR"
KERNEL_VERSION="${KERNEL_VERSION_DIR#v}" # strip leading 'v'; only adds hyphen if REV is set

# --- Download Ubuntu mainline .deb to extract its .config --------------------
UBUNTU_BASE_URL="https://kernel.ubuntu.com/~kernel-ppa/mainline/${KERNEL_VERSION_DIR}"
debug "Ubuntu mainline URL: $UBUNTU_BASE_URL"
# Ubuntu encodes version as zero-padded 6-digit string: 6.12.3 -> 061203
KERNEL_VERSION_LONG=$(echo "$KERNEL_VERSION" | awk -F. '{printf "%02d%02d%02d", $1, $2, $3}')
DEB_FILENAME="linux-modules-${KERNEL_VERSION}-${KERNEL_VERSION_LONG}-generic_${KERNEL_VERSION}-${KERNEL_VERSION_LONG}"

# Find the exact .deb name (timestamp suffix varies)
DEB_FILE=$(curl -sL "$UBUNTU_BASE_URL" |
  grep -Eo "${DEB_FILENAME}.[0-9]{12}_amd64.deb" |
  head -1) || warn "Could not find .deb for kernel ${KERNEL_VERSION} at ${UBUNTU_BASE_URL}"
[[ -z "$DEB_FILE" ]] && {
  warn "Could not find .deb ..."
  DEB_FILE=""
}

DEB_URL="${UBUNTU_BASE_URL}/amd64/${DEB_FILE}"
debug "Ubuntu .deb URL: $DEB_URL"
DEB_CACHE="$SCRIPT_DIR/${DEB_FILE}"
CONFIG_INSIDE_DEB="./boot/config-${KERNEL_VERSION}-${KERNEL_VERSION_LONG}-generic"

extract_ubuntu_config() {
  info "Extracting .config from ${DEB_FILE}..."
  dpkg-deb --fsys-tarfile "$DEB_CACHE" |
    tar xOf - "$CONFIG_INSIDE_DEB" > .config || die "Failed to extract config from deb"
  success "Config extracted."
}

fetch_ubuntu_config() {
  if [[ -f "$DEB_CACHE" ]]; then
    extract_ubuntu_config
  else
    info "Downloading kernel ${KERNEL_VERSION} config from Ubuntu mainline..."
    if [[ -n "$DEB_CACHE" ]] && wget --show-progress -O "$DEB_CACHE" -q "$DEB_URL"; then
      success "Download complete."
      extract_ubuntu_config
    else
      warn "Download failed ($DEB_URL). Falling back to running kernel config."
      cp /boot/config-"$(uname -r)" .config || die "Failed to copy running kernel config"
    fi
  fi
  # Keep a human-readable copy outside the source tree
  cp .config "$SCRIPT_DIR/config-$KERNEL_VERSION${REV:+-$REV}" || warn "Failed to save config copy outside source tree"
}

# --- Generate base config ----------------------------------------------------
info "Generating base kernel config..."
fetch_ubuntu_config

info "Applying custom kernel options..."
make CC=gcc olddefconfig || die "Configuration processing failed!\n"
# shellcheck source=kernel_config.sh
source "$KERNEL_CONFIG"
success "Custom options applied."
echo

info "Validating and updating configuration..."
cp .config "$SCRIPT_DIR/config-$KERNEL_VERSION-$LOCALVERSION"
make CC=gcc olddefconfig || die "Configuration processing failed!\n"
./scripts/diffconfig "$SCRIPT_DIR/config-$KERNEL_VERSION-$LOCALVERSION" .config \
  > "$SCRIPT_DIR/config-$KERNEL_VERSION-$LOCALVERSION".diff || die "Diffing configs failed!\n"
success "Done."
echo

# --- Summary & confirmation --------------------------------------------------
echo
git --no-pager log -1 --pretty=oneline
echo "Target system: $(uname -a)"
echo "Kernel version: ${KERNEL_VERSION}"
read -rp "Compile this kernel? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || {
  info "Aborted."
  exit 0
}

# --- Build -------------------------------------------------------------------

info "Starting build ($N_PROC threads)..."
if ! time nice make -j"$N_PROC" \
    ARCH=x86_64 \
    LOCALVERSION="-$LOCALVERSION" \
    INSTALL_MOD_STRIP=1 \
    KCFLAGS="-march=znver4 -mtune=znver4 -pipe" \
  V=$VERBOSITY \
    bindeb-pkg 2>&1 | tee ../$BUILD_LOG_FILE; then
    die "Build failed. Check $SCRIPT_DIR/$BUILD_LOG_FILE for details."
fi

# time nice make -j"$N_PROC" tools/cpupower ARCH=x86_64 | tee ../tools.log
# sudo time nice make -j"$N_PROC" tools/cpupower_install

# --- Done --------------------------------------------------------------------
success "Build successful!"
cd "$SCRIPT_DIR" || die "cd back to script dir failed."
echo
info "Install with:"
info "  sudo dpkg -i linux-image-$KERNEL_VERSION-$LOCALVERSION*.deb linux-headers-$KERNEL_VERSION-$LOCALVERSION*.deb linux-libc-dev_$KERNEL_VERSION-*.deb"
