#!/usr/bin/env bash

set -euo pipefail

DEBUG=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_CONFIG="${SCRIPT_DIR}/kernel_config.sh"

KERNEL_SRC_DIR="linux"
BUILD_LOG_FILE="kernelBuild.log"
LOCALVERSION="$(whoami)-$(hostname -s)"

# --- Helpers -----------------------------------------------------------------
info() { printf "[*] %s\n" "$@"; }
warn() { printf "[!] %s\n" "$@"; }
debug() {
  [[ $DEBUG -eq 0 ]] && return 0
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

# --- Clean & reset git -------------------------------------------------------
info "Cleanup and checkout..."
make distclean || die "make distclean failed – is this a valid kernel source tree?"
git reset --hard
git clean -df

# --- Determine kernel version from git tag -----------------------------------
KERNEL_VERSION_DIR=$(git tag --merged HEAD --sort=taggerdate | tail -n1)
KERNEL_VERSION="${KERNEL_VERSION_DIR#v}" # strip leading 'v'

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

DEB_URL="${UBUNTU_BASE_URL}/amd64/${DEB_FILE}"
debug "Ubuntu .deb URL: $DEB_URL"
DEB_CACHE="$SCRIPT_DIR/${DEB_FILE}"
CONFIG_INSIDE_DEB="./boot/config-${KERNEL_VERSION}-${KERNEL_VERSION_LONG}-generic"

extract_ubuntu_config() {
  info "Extracting .config from ${DEB_FILE}..."
  dpkg-deb --fsys-tarfile "$DEB_CACHE" |
      tar xOf - "$CONFIG_INSIDE_DEB" > .config ||
       die "Failed to extract config from deb"
  success "Config extracted."
}

fetch_ubuntu_config() {
  if [[ -f "$DEB_CACHE" ]]; then
    extract_ubuntu_config
  else
    info "Downloading kernel ${KERNEL_VERSION} config from Ubuntu mainline..."
    if [[ -n "$DEB_CACHE" ]] && wget -O "$DEB_CACHE" -q "$DEB_URL"; then
      success "Download complete."
      extract_ubuntu_config
    else
      warn "Download failed ($DEB_URL). Falling back to running kernel config."
      cp /boot/config-"$(uname -r)" .config
    fi
  fi
  # Keep a human-readable copy outside the source tree
  cp .config "$SCRIPT_DIR/config-$KERNEL_VERSION"
}

# --- Generate base config ----------------------------------------------------
info "Generating base kernel config..."
make clean
fetch_ubuntu_config
make ARCH="$(uname -m)" olddefconfig # fill in defaults for new symbols

info "Applying custom kernel options..."
# shellcheck source=kernel_config.sh
source "$KERNEL_CONFIG"
cp .config "$SCRIPT_DIR/config-$KERNEL_VERSION-$LOCALVERSION"
success "Custom options applied."

info "Validating and updating configuration..."
make ARCH="$(uname -m)" olddefconfig || die "Configuration processing failed!\n"
success "Done."

# --- Summary & confirmation --------------------------------------------------
git --no-pager log -1 --pretty=oneline
echo
echo "Target system: $(uname -a)"
echo "Kernel version: ${KERNEL_VERSION}"
echo
read -rp "Compile this kernel? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || {
  info "Aborted."
  exit 0
}

# --- Verify GCC --------------------------------------------------------------
if ! command -v gcc &> /dev/null; then
  die "GCC not found."
fi
GCC_VER=$(gcc --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
info "Using GCC ${GCC_VER}"

# --- Build -------------------------------------------------------------------
export CC="ccache gcc"
export CXX="ccache g++"
export KCFLAGS="-march=znver4 -mtune=znver4 -O2 -pipe"
export KCPPFLAGS="-march=znver4 -mtune=znver4 -O2 -pipe"

info "Starting build ($(nproc) threads)..."
if ! time nice make -j"$(nproc)" \
  ARCH=x86_64 \
  LOCALVERSION="-$LOCALVERSION" \
  INSTALL_MOD_STRIP=1 \
  bindeb-pkg |
    tee ../$BUILD_LOG_FILE; then
  die "Build failed. Check $SCRIPT_DIR/$BUILD_LOG_FILE for details."
fi

#echo performance | sudo tee /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference
# ll

# --- Done --------------------------------------------------------------------
success "Build successful!"
cd "$SCRIPT_DIR" || die "cd back to script dir failed."
echo
info "Install with:"
info "  sudo dpkg -i linux-image-$KERNEL_VERSION-$LOCALVERSION*.deb linux-headers-$KERNEL_VERSION-$LOCALVERSION*.deb"
info "  sudo update-grub"
