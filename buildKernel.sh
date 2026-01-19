#!/usr/bin/env bash

set -o pipefail
set -e

kernelSrcDir=linux

echo "Current kernel: $(uname -r)"

cd "$kernelSrcDir" || exit 1
printf "Cleanup and checkout...\n"
if ! make distclean; then # make mrproper
  printf "Did you clone kernel sources to directory: %s?\n" "$kernelSrcDir"
  exit 1
else
  git reset --hard
  git clean -d -f
#  git checkout origin/linux-rolling-stable
  #git pull origin linux-rolling-lts || exit 1
#  git pull origin linux-rolling-stable || exit 1
fi

# get kernel version from git tag
kernelVersionDir=$(git tag --merged HEAD --sort=taggerdate | tail -n1)
kernelVersion=${kernelVersionDir#v} # remove character "v" in version string

# download corresponding git module from Ubuntu mainline repo to extract and use Ubuntu kernel config
kernelUrl=https://kernel.ubuntu.com/~kernel-ppa/mainline/${kernelVersionDir}
kernelVersionLong=$(echo "$kernelVersion" | awk 'BEGIN {FS="."}{printf "%02d%02d%02d", $1, $2, $3;}')
kernelFileName=$(curl -sL "$kernelUrl" | grep -iEo "linux-modules-${kernelVersion}-${kernelVersionLong}-generic_${kernelVersion}-${kernelVersionLong}.[0-9]{12}_amd64.deb" | head -1)
kernelDeb=${kernelUrl}/amd64/${kernelFileName}

function extract_config(){
    #make xconfig or make gconfig:
    printf "Extracting config from %s... " "${kernelFileName}"
    dpkg-deb --fsys-tarfile "../${kernelFileName}" | tar xOf - ./boot/config-"${kernelVersion}"-"${kernelVersionLong}"-generic >.config || exit 1
    printf "done\n\n"
}

function get_config(){
  if [[ ! -f "../${kernelFileName}" ]]; then
   printf "Downloading kernel %s config from Ubuntu... " "$kernelVersion"
    if wget -O "../${kernelFileName}" -q "${kernelDeb}"; then      
      printf "success\n\n"
      extract_config;
    else
      printf "Problem downloading kernel %s config from Ubuntu mainline: %s.\n" "$kernelVersion" "$kernelDeb"
      printf "Using old config from current kernel %s!\n\n" "$(uname -r)"
      cp /boot/config-"$(uname -r)" .config
    fi
  else
    extract_config;
  fi

  cp .config ../config-"${kernelVersion}" || exit 1
}

printf "Making new kernel config...\n"
make clean
get_config;
make ARCH="$(uname -m)" olddefconfig #oldconfig or olddefconfig = use defaults for new options

printf "Modify kernel options...\n"
#./scripts/config --enable CONFIG_X86_NATIVE_CPU # optimize for installed CPU (since 6.16)

# Optimizations:
echo "=== Applying Zen 4 Optimizations ==="

# === Compiler-Optimierung ===
./scripts/config --enable CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE  # -O2 für Desktop
# Alternative für kleinere Größe:
# ./scripts/config --enable CONFIG_CC_OPTIMIZE_FOR_SIZE  # -Os
# scripts/config --enable CONFIG_LTO_CLANG_THIN        # Wenn Clang verwendet
./scripts/config --disable CONFIG_GCC_PLUGINS

# === Module Compression ===
./scripts/config --enable CONFIG_MODULE_COMPRESS_ZSTD
./scripts/config --disable CONFIG_MODULE_COMPRESS_GZIP

# === Initramfs (Mint BRAUCHT das!) ===
./scripts/config --enable CONFIG_BLK_DEV_INITRD
./scripts/config --enable CONFIG_RD_GZIP
./scripts/config --enable CONFIG_RD_ZSTD

# For gaming/desktop performance:
./scripts/config --enable CONFIG_HZ_PERIODIC
./scripts/config --disable CONFIG_NO_HZ_FULL  # Unless you need CPU isolation
./scripts/config --enable CONFIG_TICK_CPU_ACCOUNTING
./scripts/config --disable CONFIG_VIRT_CPU_ACCOUNTING_GEN
# Disable PPS kernel consumer (not needed for desktop)
./scripts/config --disable CONFIG_NTP_PPS

# Modern AMD features:
./scripts/config --enable CONFIG_AMD_MEM_ENCRYPT  # SME/SEV support
./scripts/config --enable CONFIG_AMD_MEM_ENCRYPT_ACTIVE_BY_DEFAULT
# Better latency:
./scripts/config --set-val CONFIG_RCU_BOOST_DELAY 500

## AMD-specific optimizations
./scripts/config --enable CONFIG_X86_64_V4          # Zen4 Native
./scripts/config --disable CONFIG_X86_32_LAZY_GS    # Nicht benötigt
./scripts/config --disable CONFIG_GENERIC_CPU
./scripts/config --disable CONFIG_X86_32
./scripts/config --disable CONFIG_MAXSMP
./scripts/config --enable CONFIG_MZEN4 # AMD Ryzen4 7950X3D  optimization
./scripts/config --enable CONFIG_AMD_NB
./scripts/config --enable CONFIG_EDAC_DECODE_MCE
./scripts/config --enable CONFIG_EDAC_AMD64
./scripts/config --enable CONFIG_CPU_SUP_AMD
./scripts/config --enable CONFIG_AMD_IOMMU
./scripts/config --enable CONFIG_AMD_IOMMU_V2
./scripts/config --enable CONFIG_HWMON
#./scripts/config --enable CONFIG_SENSORS_ASUS_EC  # Für MSI/ASUS Boards
./scripts/config --enable CONFIG_NCT6683
./scripts/config --enable CONFIG_SENSORS_NCT6687
./scripts/config --enable CONFIG_SENSORS_K10TEMP
./scripts/config --enable CONFIG_SENSORS_FAM15H_POWER
./scripts/config --enable CONFIG_CRYPTO_AES_NI_INTEL  # Still useful on AMD
./scripts/config --enable CONFIG_CRYPTO_AVX2
./scripts/config --enable CONFIG_CRYPTO_SHA256_SSSE3

# ACPI für Desktop
./scripts/config --enable CONFIG_ACPI
./scripts/config --enable CONFIG_ACPI_AC
./scripts/config --enable CONFIG_ACPI_BATTERY
./scripts/config --enable CONFIG_ACPI_BUTTON

# USB Support
./scripts/config --enable CONFIG_USB_SUPPORT
./scripts/config --enable CONFIG_USB_XHCI_HCD
./scripts/config --enable CONFIG_USB_EHCI_HCD
# === Input Devices (Maus/Tastatur) ===
./scripts/config --enable CONFIG_INPUT_EVDEV
./scripts/config --enable CONFIG_HID_GENERIC
./scripts/config --enable CONFIG_USB_HID

# Enable 3D V-Cache optimizations
./scripts/config --enable CONFIG_X86_AMD_FREQ_SENSITIVITY

# Set correct processor count (16 cores, 32 threads)
./scripts/config --set-val CONFIG_NR_CPUS 32

# Enable preemption for desktop responsiveness
# ./scripts/config --enable CONFIG_PREEMPT
./scripts/config --enable CONFIG_PREEMPT_DYNAMIC
./scripts/config --disable CONFIG_PREEMPT_VOLUNTARY
./scripts/config --disable CONFIG_PREEMPT_NONE

# Timer frequency - 1000 Hz for desktop (smoother)
## High resolution timer
./scripts/config --disable CONFIG_HZ_250
./scripts/config --disable CONFIG_HZ_500
./scripts/config --enable CONFIG_HZ_1000
./scripts/config --set-val CONFIG_HZ 1000

# Memory optimizations for 64GB DDR5
./scripts/config --enable CONFIG_TRANSPARENT_HUGEPAGE
./scripts/config --enable CONFIG_TRANSPARENT_HUGEPAGE_MADVISE
./scripts/config --disable CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS
./scripts/config --enable CONFIG_COMPACTION
./scripts/config --enable CONFIG_MIGRATION

# PCIe 5.0 support (X670E feature)
./scripts/config --enable CONFIG_PCIEAER
./scripts/config --enable CONFIG_PCIEASPM

# RICHTIG für 7950X3D:
./scripts/config --enable CONFIG_CPU_FREQ
./scripts/config --enable CONFIG_X86_AMD_PSTATE
#./scripts/config --enable CONFIG_X86_AMD_PSTATE_UT     # Optional: Unit Tests

# Performance Governor
./scripts/config --enable CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL
./scripts/config --enable CONFIG_CPU_FREQ_GOV_SCHEDUTIL
./scripts/config --enable CONFIG_CPU_FREQ_GOV_PERFORMANCE

# Andere Governors deaktivieren (spart Platz)
./scripts/config --disable CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE
./scripts/config --disable CONFIG_CPU_FREQ_DEFAULT_GOV_POWERSAVE
./scripts/config --disable CONFIG_CPU_FREQ_DEFAULT_GOV_USERSPACE
./scripts/config --disable CONFIG_CPU_FREQ_DEFAULT_GOV_ONDEMAND
./scripts/config --disable CONFIG_CPU_FREQ_DEFAULT_GOV_CONSERVATIVE

# Optional: Andere Governors komplett entfernen
./scripts/config --disable CONFIG_CPU_FREQ_GOV_ONDEMAND
./scripts/config --disable CONFIG_CPU_FREQ_GOV_CONSERVATIVE
./scripts/config --disable CONFIG_CPU_FREQ_GOV_POWERSAVE
./scripts/config --disable CONFIG_X86_ACPI_CPUFREQ

## Disable AMD GPU drivers (not needed - AMD GPU disabled in BIOS, using NVIDIA)
./scripts/config --disable CONFIG_DRM_AMDGPU
./scripts/config --disable CONFIG_DRM_AMDGPU_CIK
./scripts/config --disable CONFIG_DRM_AMDGPU_SI
./scripts/config --disable CONFIG_DRM_RADEON
# === Sound: Kein HDMI Audio ===
./scripts/config --disable CONFIG_SND_HDA_CODEC_HDMI
./scripts/config --disable CONFIG_SND_HDA_INTEL_HDMI_SILENT_STREAM
# AMD HD Audio behalten (für Mainboard)
./scripts/config --enable CONFIG_SND_HDA_INTEL
./scripts/config --enable CONFIG_SND_HDA_CODEC_REALTEK
./scripts/config --enable CONFIG_SND_HDA_CODEC_GENERIC
# PulseAudio/PipeWire Support
./scripts/config --enable CONFIG_SND_TIMER
./scripts/config --enable CONFIG_SND_PCM
## Disable unused GPU drivers
# ./scripts/config --disable CONFIG_DRM_NOUVEAU
./scripts/config --disable CONFIG_DRM_I915
./scripts/config --disable CONFIG_DRM_XE
./scripts/config --disable CONFIG_DRM_VMWGFX
./scripts/config --disable CONFIG_DRM_QXL
./scripts/config --disable CONFIG_DRM_VIRTIO_GPU
./scripts/config --disable CONFIG_DRM_BOCHS
./scripts/config --disable CONFIG_DRM_CIRRUS_QEMU
./scripts/config --disable CONFIG_DRM_VGEM
./scripts/config --disable CONFIG_DRM_VKMS
./scripts/config --disable CONFIG_DRM_UDL
./scripts/config --disable CONFIG_DRM_AST
./scripts/config --disable CONFIG_DRM_MGAG200
./scripts/config --disable CONFIG_DRM_GMA500
# ./scripts/config --disable CONFIG_DRM_HYPERV
# ./scripts/config --disable CONFIG_DRM_VBOXVIDEO
./scripts/config --disable CONFIG_DRM_ACCEL_HABANALABS
./scripts/config --disable CONFIG_DRM_ACCEL_IVPU
./scripts/config --disable CONFIG_DRM_ACCEL_QAIC
./scripts/config --disable CONFIG_DRM_ACCEL_AMDXDNA

# IPv4/IPv6 (Mint braucht das)
./scripts/config --enable CONFIG_INET
./scripts/config --enable CONFIG_IPV6

# === Mint-spezifisch: Flatpak/Snap Support ===
./scripts/config --enable CONFIG_USER_NS
./scripts/config --enable CONFIG_CGROUPS
./scripts/config --enable CONFIG_NAMESPACES

# AppArmor (Mint nutzt das standardmäßig)
./scripts/config --enable CONFIG_SECURITY_APPARMOR
./scripts/config --enable CONFIG_DEFAULT_SECURITY_APPARMOR

## Disable unused Ethernets
# RTL8125 2.5GbE für X670E onboard LAN behalten, Rest weg
# Bluetooth behalten, WiFi aus
./scripts/config --enable CONFIG_BT
./scripts/config --enable CONFIG_BT_RFCOMM
./scripts/config --enable CONFIG_BT_HIDP
./scripts/config --disable CONFIG_WIRELESS
./scripts/config --disable CONFIG_WLAN
./scripts/config --disable CONFIG_CFG80211
./scripts/config --disable CONFIG_MAC80211
./scripts/config --disable CONFIG_IWLWIFI
./scripts/config --disable CONFIG_ATH9K
./scripts/config --disable CONFIG_ATH11K
./scripts/config --disable CONFIG_RT2X00
./scripts/config --disable CONFIG_MT76
# Ethernet behalten (X670E hat meist Realtek/Intel)
./scripts/config --enable CONFIG_NET_VENDOR_REALTEK
./scripts/config --enable CONFIG_R8169  # Für RTL8125 Realtek 2.5GbE

./scripts/config --disable CONFIG_E1000E          # Intel
./scripts/config --disable CONFIG_NET_VENDOR_INTEL
./scripts/config --disable CONFIG_NET_VENDOR_3COM
./scripts/config --disable CONFIG_NET_VENDOR_ADAPTEC
./scripts/config --disable CONFIG_NET_VENDOR_AGERE
./scripts/config --disable CONFIG_NET_VENDOR_ALTEON
./scripts/config --disable CONFIG_NET_VENDOR_AMAZON
./scripts/config --disable CONFIG_NET_VENDOR_AMD  # Netzwerk, nicht GPU
./scripts/config --disable CONFIG_NET_VENDOR_AQUANTIA
./scripts/config --disable CONFIG_NET_VENDOR_ARC
./scripts/config --disable CONFIG_NET_VENDOR_ATHEROS
./scripts/config --disable CONFIG_NET_VENDOR_BROADCOM
./scripts/config --disable CONFIG_NET_VENDOR_CADENCE
./scripts/config --disable CONFIG_NET_VENDOR_CAVIUM
./scripts/config --disable CONFIG_NET_VENDOR_CHELSIO
./scripts/config --disable CONFIG_NET_VENDOR_CISCO
./scripts/config --disable CONFIG_NET_VENDOR_CORTINA
./scripts/config --disable CONFIG_NET_VENDOR_DEC
./scripts/config --disable CONFIG_NET_VENDOR_DLINK
./scripts/config --disable CONFIG_NET_VENDOR_EMULEX
./scripts/config --disable CONFIG_NET_VENDOR_EZCHIP
./scripts/config --disable CONFIG_NET_VENDOR_GOOGLE
./scripts/config --disable CONFIG_NET_VENDOR_HUAWEI
./scripts/config --disable CONFIG_NET_VENDOR_MARVELL
./scripts/config --disable CONFIG_NET_VENDOR_MELLANOX
./scripts/config --disable CONFIG_NET_VENDOR_MICREL
./scripts/config --disable CONFIG_NET_VENDOR_MICROCHIP
./scripts/config --disable CONFIG_NET_VENDOR_MICROSEMI
./scripts/config --disable CONFIG_NET_VENDOR_MYRICOM
./scripts/config --disable CONFIG_NET_VENDOR_NATSEMI
./scripts/config --disable CONFIG_NET_VENDOR_NETERION
./scripts/config --disable CONFIG_NET_VENDOR_NETRONOME
./scripts/config --disable CONFIG_NET_VENDOR_NI
./scripts/config --disable CONFIG_NET_VENDOR_NVIDIA
./scripts/config --disable CONFIG_NET_VENDOR_OKI
./scripts/config --disable CONFIG_NET_VENDOR_PACKET_ENGINES
./scripts/config --disable CONFIG_NET_VENDOR_QLOGIC
./scripts/config --disable CONFIG_NET_VENDOR_QUALCOMM
./scripts/config --disable CONFIG_NET_VENDOR_RDC
./scripts/config --disable CONFIG_NET_VENDOR_ROCKER
./scripts/config --disable CONFIG_NET_VENDOR_SAMSUNG
./scripts/config --disable CONFIG_NET_VENDOR_SEEQ
./scripts/config --disable CONFIG_NET_VENDOR_SILAN
./scripts/config --disable CONFIG_NET_VENDOR_SIS
./scripts/config --disable CONFIG_NET_VENDOR_SMSC
./scripts/config --disable CONFIG_NET_VENDOR_STMICRO
./scripts/config --disable CONFIG_NET_VENDOR_SUN
./scripts/config --disable CONFIG_NET_VENDOR_SYNOPSYS
./scripts/config --disable CONFIG_NET_VENDOR_TEHUTI
./scripts/config --disable CONFIG_NET_VENDOR_TI
./scripts/config --disable CONFIG_NET_VENDOR_VIA
./scripts/config --disable CONFIG_NET_VENDOR_WIZNET
./scripts/config --disable CONFIG_NET_VENDOR_XILINX
## MSI X670E Carbon specific
./scripts/config --enable CONFIG_X86_AMD_PLATFORM_DEVICE
./scripts/config --enable CONFIG_I2C_PIIX4       # AMD SMBus
./scripts/config --enable CONFIG_PINCTRL_AMD
./scripts/config --enable CONFIG_GPIO_AMD_FCH
## IOMMU for better GPU isolation
./scripts/config --enable CONFIG_VFIO
./scripts/config --enable CONFIG_VFIO_PCI

# Framebuffer minimal (für Console)
./scripts/config --enable CONFIG_FB
./scripts/config --enable CONFIG_FB_EFI
./scripts/config --enable CONFIG_DRM
./scripts/config --enable CONFIG_DRM_FBDEV_EMULATION
./scripts/config --disable CONFIG_FB_NVIDIA # TODO ???

## Better NVIDIA support
./scripts/config --enable CONFIG_DRM_SIMPLEDRM  # For boot framebuffer with NVIDIA
./scripts/config --enable CONFIG_FB_VESA        # VESA framebuffer support
./scripts/config --enable CONFIG_DRM_NVIDIA
./scripts/config --disable CONFIG_SOUND_HDA_CODEC_HDMI
## Better SSD performance (NVMe)
./scripts/config --enable CONFIG_NVME_CORE
./scripts/config --enable CONFIG_BLK_DEV_NVME
./scripts/config --enable CONFIG_NVME_MULTIPATH
./scripts/config --enable CONFIG_NVME_HWMON
## I/O schedulers
./scripts/config --enable CONFIG_MQ_IOSCHED_DEADLINE
./scripts/config --enable CONFIG_IOSCHED_BFQ
./scripts/config --enable CONFIG_BFQ_GROUP_IOSCHED
./scripts/config --set-str CONFIG_DEFAULT_IOSCHED "bfq"
## Better network stack
./scripts/config --enable CONFIG_NET_SCH_FQ
./scripts/config --enable CONFIG_NET_SCH_FQ_CODEL
./scripts/config --set-str CONFIG_DEFAULT_TCP_CONG "bbr"
./scripts/config --enable CONFIG_TCP_CONG_BBR
## Disable some mitigations for performance (if security allows) - KEEP COMMENTED FOR SECURITY
# ./scripts/config --disable CONFIG_RETPOLINE
# ./scripts/config --disable CONFIG_CPU_SPEC_STORE_BYPASS_DISABLE
# ./scripts/config --disable CONFIG_PAGE_TABLE_ISOLATION
./scripts/config --disable CONFIG_SECURITY_SELINUX
# ./scripts/config --disable CONFIG_SECURITY_SMACK
# ./scripts/config --disable CONFIG_IMA

## Additional performance tweaks
./scripts/config --enable CONFIG_X86_X2APIC
./scripts/config --enable CONFIG_HAVE_PERF_EVENTS_NMI

# NVMe: Optimierter Queue
./scripts/config --set-val CONFIG_BLK_DEV_NVME_NUM_QUEUES 8 # for PCIe 4.0 x4 SSDs

# Gaming: BBR + Cake
./scripts/config --enable CONFIG_NET_SCH_CAKE

# === Gaming: Controller Support ===
./scripts/config --disable CONFIG_INPUT_JOYDEV
./scripts/config --disable CONFIG_JOYSTICK_XPAD        # Xbox Controller
./scripts/config --disable CONFIG_HID_PLAYSTATION      # PS5 Controller
./scripts/config --disable CONFIG_HID_STEAM            # Steam Controller

# === Unnötige Subsysteme ===
./scripts/config --disable CONFIG_HAMRADIO
./scripts/config --disable CONFIG_CAN
./scripts/config --disable CONFIG_NFC
./scripts/config --disable CONFIG_WIMAX
./scripts/config --disable CONFIG_PCMCIA
./scripts/config --disable CONFIG_FIREWIRE

# === Faster Boot ===
./scripts/config --disable CONFIG_PRINTK_TIME
./scripts/config --disable CONFIG_BOOT_PRINTK_DELAY

# Ungenutzte Netzwerk-Protokolle
./scripts/config --disable CONFIG_IPX
./scripts/config --disable CONFIG_ATALK
./scripts/config --disable CONFIG_X25
./scripts/config --disable CONFIG_DECNET

# Alte Hardware
./scripts/config --disable CONFIG_INFINIBAND
./scripts/config --disable CONFIG_PHONE
./scripts/config --disable CONFIG_ARCNET
./scripts/config --disable CONFIG_ISDN
./scripts/config --disable CONFIG_PARPORT
./scripts/config --disable CONFIG_BLK_DEV_FD

# Alte CPU-Features raus
./scripts/config --disable CONFIG_X86_ANCIENT_MCE
./scripts/config --disable CONFIG_X86_MCE_AMD
./scripts/config --disable CONFIG_CPU_SUP_INTEL
./scripts/config --disable CONFIG_CPU_SUP_CENTAUR
./scripts/config --disable CONFIG_CPU_SUP_ZHAOXIN

# === Dateisysteme ===
./scripts/config --enable CONFIG_EXT4_FS
./scripts/config --enable CONFIG_BTRFS_FS
./scripts/config --enable CONFIG_VFAT_FS
./scripts/config --enable CONFIG_NTFS3_FS
./scripts/config --enable CONFIG_FUSE_FS  # Für AppImage, etc.
./scripts/config --enable CONFIG_OVERLAY_FS # Für Flatpak/Snap
./scripts/config --enable CONFIG_TMPFS
./scripts/config --enable CONFIG_PROC_FS
./scripts/config --enable CONFIG_SYSFS


# Exotische Dateisysteme raus
./scripts/config --disable CONFIG_REISERFS_FS
./scripts/config --disable CONFIG_JFS_FS
# ./scripts/config --disable CONFIG_F2FS_FS
./scripts/config --disable CONFIG_NILFS2_FS
./scripts/config --disable CONFIG_EROFS_FS
./scripts/config --disable CONFIG_XFS_FS

echo "=== DEBUGGING ==="
./scripts/config --disable CONFIG_DEBUG_KERNEL
./scripts/config --disable CONFIG_DEBUG_INFO
./scripts/config --disable CONFIG_FTRACE
./scripts/config --disable CONFIG_KPROBES
./scripts/config --disable CONFIG_DEBUG_INFO_DWARF4
./scripts/config --disable CONFIG_DEBUG_INFO_DWARF5
./scripts/config --disable CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
./scripts/config --disable CONFIG_DEBUG_FS
./scripts/config --disable CONFIG_KCOV
./scripts/config --disable CONFIG_PROVE_LOCKING
./scripts/config --disable CONFIG_LOCK_DEBUGGING_SUPPORT
./scripts/config --disable CONFIG_LOCK_STAT
./scripts/config --disable CONFIG_KGDB
./scripts/config --disable CONFIG_UBSAN
./scripts/config --disable CONFIG_KASAN
./scripts/config --disable CONFIG_DEBUG_KMAP_LOCAL_FORCE_MAP
./scripts/config --disable CONFIG_PAGE_OWNER
./scripts/config --disable CONFIG_DEBUG_OBJECTS

# Disable specific DRM debug options
./scripts/config --disable CONFIG_DRM_DEBUG_DP_MST_TOPOLOGY_REFS
./scripts/config --disable CONFIG_DRM_DEBUG_MODESET_LOCK
./scripts/config --disable CONFIG_DRM_PANIC_DEBUG

#./scripts/config --disable MODULE_SIG
#./scripts/config --disable CONFIG_MODULE_SIG_ALL
./scripts/config --set-str CONFIG_SYSTEM_REVOCATION_KEYS ""
./scripts/config --set-str CONFIG_SYSTEM_TRUSTED_KEYS ""

printf "done!\n"

#printf "Validating configuration...\n"
#if ! make ARCH="$(uname -m)" olddefconfig; then
#    printf "Configuration validation failed!\n"
#    exit 1
#fi
#printf "done\n"

printf "Modify optimizations in Makefile... "
sed -i 's/-O2/-O3/g' Makefile
printf "done\n"

git --no-pager log -1 --pretty=oneline
echo "Do you wish to compile this kernel for $(uname -a)?"
echo "$ARCH"
select yn in "Yes" "No"; do
  case $yn in
    Yes) break ;;
    No) exit 1 ;;
  esac
done

printf "Checking for GCC 14... "
if command -v gcc >/dev/null 2>&1; then
    GCC_VERSION=$(gcc --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    printf "found GCC %s\n" "$GCC_VERSION"
else
    printf "not found. Exiting!\n"
    exit 1
fi

printf "time make clean build...\n"
export CC="ccache gcc"
export CXX="ccache g++"
export KCFLAGS="-march=znver4 -mtune=znver4 -O3 -pipe"
export KCPPFLAGS="-march=znver4 -mtune=znver4 -O3 -pipe"

if ! time nice make -j$(($(nproc) * 2)) ARCH=x86_64 bindeb-pkg INSTALL_MOD_STRIP=1 LOCALVERSION=-"$(whoami)"-"$(hostname -s)-3" | tee ../log; then
  # O=../build-dir
  printf "Build failed!"
  exit 1
else
  printf "Successfully built with optimization.\n"
  cd .. || exit 1
  printf "...done!\nYou can install now using:\nsudo dpkg -i linux-image-%s-%s-%s*.deb linux-headers-%s-%s-%s*.deb && sudo update-grub\n" "${kernelVersion}" "$(whoami)" "$(hostname -s)" "${kernelVersion}" "$(whoami)" "$(hostname -s)"
fi
