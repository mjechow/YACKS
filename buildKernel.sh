#!/usr/bin/env bash


set -euo pipefail

KERNEL_SRC_DIR="linux"
BUILD_LOG_FILE="kernelBuild.log"

# --- Helpers -----------------------------------------------------------------
die()    { printf "ERROR: %s\n" "$*" >&2; exit 1; }
info()   { printf "[*] %s\n" "$*"; }
success() { printf "[+] %s\n" "$*"; }

# --- Sanity checks -----------------------------------------------------------
info "Current kernel: $(uname -r)"

cd "$KERNEL_SRC_DIR" 2>/dev/null \
    || die "Kernel source directory '$KERNEL_SRC_DIR' not found. Did you clone the kernel sources?"

# --- Clean & reset git -------------------------------------------------------
info "Cleanup and checkout..."
make distclean || die "make distclean failed – is this a valid kernel source tree?"
git reset --hard
git clean -df

# --- Determine kernel version from git tag -----------------------------------
KERNEL_VERSION_DIR=$(git tag --merged HEAD --sort=taggerdate | tail -n1)
KERNEL_VERSION="${KERNEL_VERSION_DIR#v}"   # strip leading 'v'

# --- Download Ubuntu mainline .deb to extract its .config --------------------
UBUNTU_BASE_URL="https://kernel.ubuntu.com/~kernel-ppa/mainline/${KERNEL_VERSION_DIR}"
# Ubuntu encodes version as zero-padded 6-digit string: 6.12.3 -> 061203
KERNEL_VERSION_LONG=$(echo "$KERNEL_VERSION" | awk -F. '{printf "%02d%02d%02d", $1, $2, $3}')
DEB_FILENAME="linux-modules-${KERNEL_VERSION}-${KERNEL_VERSION_LONG}-generic_${KERNEL_VERSION}-${KERNEL_VERSION_LONG}"

# Find the exact .deb name (timestamp suffix varies)
DEB_FILE=$(curl -sL "$UBUNTU_BASE_URL" \
    | grep -oE "${DEB_FILENAME}\.[0-9]{12}_amd64\.deb" \
    | head -1)
[[ -n "$DEB_FILE" ]] || die "Could not find .deb for kernel ${KERNEL_VERSION} at ${UBUNTU_BASE_URL}"

DEB_URL="${UBUNTU_BASE_URL}/amd64/${DEB_FILE}"
DEB_CACHE="../${DEB_FILE}"
CONFIG_INSIDE_DEB="./boot/config-${KERNEL_VERSION}-${KERNEL_VERSION_LONG}-generic"

extract_ubuntu_config() {
    info "Extracting .config from ${DEB_FILE}..."
    dpkg-deb --fsys-tarfile "$DEB_CACHE" \
        | tar xOf - "$CONFIG_INSIDE_DEB" > .config \
        || die "Failed to extract config from deb"
    success "Config extracted."
}

fetch_ubuntu_config() {
    if [[ -f "$DEB_CACHE" ]]; then
        extract_ubuntu_config
    else
        info "Downloading kernel ${KERNEL_VERSION} config from Ubuntu mainline..."
        if wget -q -O "$DEB_CACHE" "$DEB_URL"; then
            success "Download complete."
            extract_ubuntu_config
        else
            printf "WARNING: Download failed (%s). Falling back to running kernel config.\n" "$DEB_URL"
            cp /boot/config-"$(uname -r)" .config
        fi
    fi
    # Keep a human-readable copy outside the source tree
    cp .config "../config-${KERNEL_VERSION}"
}

# --- Generate base config ----------------------------------------------------
info "Generating base kernel config..."
make clean
fetch_ubuntu_config
make ARCH="$(uname -m)" olddefconfig   # fill in defaults for new symbols

info "Applying custom kernel options..."
source "../kernel_config.sh"
success "Custom options applied."

info "Validating configuration..."
if ! make ARCH="$(uname -m)" olddefconfig; then
    printf "Configuration validation failed!\n"
    exit 1
fi
success "Done."

# --- Summary & confirmation --------------------------------------------------
git --no-pager log -1 --pretty=oneline
echo
echo "Target system: $(uname -a)"
echo "Kernel version: ${KERNEL_VERSION}"
echo
read -rp "Compile this kernel? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }

# --- Verify GCC --------------------------------------------------------------
if ! command -v gcc &>/dev/null; then
    die "GCC not found."
fi
GCC_VER=$(gcc --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
info "Using GCC ${GCC_VER}"

# --- Build -------------------------------------------------------------------
export CC="ccache gcc"
export CXX="ccache g++"
export KCFLAGS="-march=znver4 -mtune=znver4 -O2 -pipe"
export KCPPFLAGS="-march=znver4 -mtune=znver4 -O2 -pipe"

LOCALVERSION="-$(whoami)-$(hostname -s)"

info "Starting build ($(nproc) threads)..."
if ! time nice make -j"$(nproc)" \
        ARCH=x86_64 \
        LOCALVERSION="$LOCALVERSION" \
        INSTALL_MOD_STRIP=1 \
        bindeb-pkg \
        | tee ../$BUILD_LOG_FILE; then
    die "Build failed. Check ../$BUILD_LOG_FILE for details."
fi

#echo performance | sudo tee /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference

# --- Done --------------------------------------------------------------------
success "Build successful!"
cd .. || exit 1
echo
echo "Install with:"
printf "  sudo dpkg -i linux-image-%s%s*.deb linux-headers-%s%s*.deb\n" \
    "$KERNEL_VERSION" "$LOCALVERSION" "$KERNEL_VERSION" "$LOCALVERSION"
printf "  sudo update-grub\n"
