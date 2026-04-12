#!/usr/bin/env bash

# ==============================================================================
# kernel_config.sh – Kernel-Konfigurationsoptionen
# ==============================================================================
# Kernel config customization – MSI X670E / Ryzen 9 7950X3D / RTX 3070 / Mint
# ==============================================================================
# Hardware:
#   Mainboard: MSI MPG X670E Carbon WiFi
#   CPU:       AMD Ryzen 9 7950X3D (Zen 4, 16c/32t)
#   RAM:       Kingston FURY Beast 64 GB DDR5-6000 CL30-36-36 (KF560C30BBEK2-64) (KF560C30-32 x2)
#   SSD:       Samsung 970 EVO Plus 1 TB (NVMe PCIe 3.0 x4) btrfs/ext4
#   HDD:       Western Digital WD Caviar Green 1TB ntfs
#   SSD2:      Lexar NM620 1TB ntfs
#   SSD3:      Samsung SSD 850 EVO 500GB ntfs
#   GPU:       NVIDIA GeForce RTX 3070 (AMD GPU disabled in BIOS)
#   Sound:     Onboard (Realtek via HDA Intel) – no HDMI audio
#   Network:   Realtek RTL8125 2.5GbE onboard – WiFi unused, Bluetooth used
#   OS:        Linux Mint 22.3
# External Hardware
#   Keyboard:       Logitech MX Keys (USB receiver)
#   Mouse:          Asus ROG Keris Wireless Aimpoint (USB receiver)
#   Monitor:        Asus ProArt PA278CGRV (2560x1440, 144 Hz, DisplayPort)
#   Webcam:         Logitech C920 (USB) v4l2
#   DVD-Writer:     TSSTcorp SH-S203D CDRFS/UDF
#	  USB Dock:       Anker 675
#   Printer:        Color Laser Jet Pro MFP M477fdn
#   SDCard Reader:  Lexar USB 3.0 LRW400U Rev A (connected via USB) exfat
#   SD Card Reader: Graugear G-MP01CR fat/fat32
#   HeadSet:        BeyerDynamic MMX 200
#   Smartphone:     Samsung S20FE  YAFFS/f2fs/vfat/sdcardfs
# ==============================================================================

echo "Kernel config here!"

# --- Compiler & LTO ----------------------------------------------------------
./scripts/config --keep-case --enable  CONFIG_LTO_NONE
./scripts/config --keep-case --disable CONFIG_LTO_CLANG
./scripts/config --keep-case --disable CONFIG_LTO_CLANG_FULL
./scripts/config --keep-case --disable CONFIG_LTO_CLANG_THIN   # sets LTO_CLANG implicitly # ThinLTO — faster than full LTO,
./scripts/config --keep-case --disable CONFIG_GCC_PLUGINS       # unused, saves compile time
./scripts/config --keep-case --disable CONFIG_LTO_GCC
./scripts/config --keep-case --disable CONFIG_LTO
./scripts/config --keep-case --enable  CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE # -O2
./scripts/config --keep-case --disable CONFIG_CC_OPTIMIZE_FOR_SIZE

# CFI — Clang kernel Control Flow Integrity (security + sometimes perf)
# Only available with LLVM builds:
./scripts/config --keep-case --disable CONFIG_CFI_CLANG        # optional but CachyOS includes it
./scripts/config --keep-case --disable CONFIG_CFI_PERMISSIVE  # enforce, don't just warn

# --- Module compression (zstd is faster than gzip on modern CPUs) -----		-------
./scripts/config --keep-case --enable  CONFIG_MODULE_COMPRESS
./scripts/config --keep-case --enable  CONFIG_MODULE_COMPRESS_ALL
./scripts/config --keep-case --enable  CONFIG_MODULE_COMPRESS_ZSTD
./scripts/config --keep-case --disable CONFIG_MODULE_DECOMPRESS
./scripts/config --keep-case --disable CONFIG_MODULE_COMPRESS_GZIP
./scripts/config --keep-case --disable CONFIG_MODULE_COMPRESS_XZ
./scripts/config --keep-case --disable CONFIG_MODULE_COMPRESS_NONE
# --- Firmware with zstd compression support ----------------------------------
./scripts/config --keep-case --enable CONFIG_FW_LOADER
./scripts/config --keep-case --enable CONFIG_FW_LOADER_COMPRESS
./scripts/config --keep-case --enable CONFIG_FW_LOADER_COMPRESS_ZSTD
./scripts/config --keep-case --enable CONFIG_FW_LOADER_USER_HELPER

# --- Swap compression (zswap) ------------------------------------------------
./scripts/config --keep-case --enable  CONFIG_ZSWAP
./scripts/config --keep-case --enable  CONFIG_ZSWAP_DEFAULT_ON
./scripts/config --keep-case --enable  CONFIG_ZSWAP_SHRINKER_DEFAULT_ON
./scripts/config --keep-case --enable  CONFIG_CRYPTO_ZSTD
./scripts/config --keep-case --enable  CONFIG_ZSWAP_COMPRESSOR_DEFAULT_ZSTD
./scripts/config --keep-case --set-str CONFIG_ZSWAP_COMPRESSOR_DEFAULT "zstd"  # redundant aber dokumentiert Intent
./scripts/config --keep-case --disable CONFIG_ZSWAP_COMPRESSOR_DEFAULT_LZO

# --- Initramfs (required by Mint) --------------------------------------------
./scripts/config --keep-case --enable CONFIG_BLK_DEV_INITRD
./scripts/config --keep-case --enable CONFIG_RD_GZIP
./scripts/config --keep-case --enable CONFIG_RD_ZSTD

# --- Timer & scheduling ------------------------------------------------------
./scripts/config --keep-case --enable  CONFIG_TICK_CPU_ACCOUNTING
./scripts/config --keep-case --disable CONFIG_VIRT_CPU_ACCOUNTING_GEN
./scripts/config --keep-case --disable CONFIG_NTP_PPS # desktop doesn't need PPS
./scripts/config --keep-case --disable  CONFIG_SCHED_CLASS_EXT
./scripts/config --keep-case --disable CONFIG_SCHED_CORE
./scripts/config --keep-case --enable  CONFIG_SCHED_AUTOGROUP # groups processes by TTY session; prevents make -j32 from starving the desktop

# Per-VMA locking — reduces mmap_lock contention (upstream since 6.3)
./scripts/config --keep-case --enable CONFIG_PER_VMA_LOCK
# mglru (Multi-Gen LRU) — better page reclaim, upstream since 6.1
./scripts/config --keep-case --enable CONFIG_LRU_GEN
./scripts/config --keep-case --enable CONFIG_LRU_GEN_ENABLED

# --- Preemption (dynamic = best of both worlds on desktop) ------------------
./scripts/config --keep-case --enable CONFIG_PREEMPT
./scripts/config --keep-case --enable CONFIG_PREEMPT_DYNAMIC
./scripts/config --keep-case --disable CONFIG_PREEMPT_VOLUNTARY
./scripts/config --keep-case --disable CONFIG_PREEMPT_NONE

# --- Timer frequency: 1000 Hz for smooth desktop ----------------------------
./scripts/config --keep-case --disable CONFIG_HZ_PERIODIC
./scripts/config --keep-case --disable CONFIG_NO_HZ_FULL # For CPU isolation if needed
./scripts/config --keep-case --enable  CONFIG_NO_HZ_COMMON
./scripts/config --keep-case --enable  CONFIG_NO_HZ_IDLE # Better for desktop
./scripts/config --keep-case --disable CONFIG_HZ_250
./scripts/config --keep-case --disable CONFIG_HZ_500
./scripts/config --keep-case --enable  CONFIG_HZ_1000
./scripts/config --keep-case --set-val CONFIG_HZ 1000

# --- CPU: AMD Zen 4 / Ryzen 9 7950X3D ---------------------------------------
./scripts/config --keep-case --enable  CONFIG_SCHED_MC_PRIO
./scripts/config --keep-case --enable  CONFIG_SCHED_MC
./scripts/config --keep-case --enable  CONFIG_SCHED_SMT
./scripts/config --keep-case --enable  CONFIG_CPU_SUP_AMD
./scripts/config --keep-case --disable CONFIG_CPU_SUP_INTEL
./scripts/config --keep-case --disable CONFIG_CPU_SUP_CENTAUR
./scripts/config --keep-case --disable CONFIG_CPU_SUP_ZHAOXIN
./scripts/config --keep-case --set-val CONFIG_NR_CPUS 32 # 16 cores / 32 threads
./scripts/config --keep-case --disable CONFIG_GENERIC_CPU
./scripts/config --keep-case --disable CONFIG_X86_64_V3 # use -march=znver4 instead
./scripts/config --keep-case --disable CONFIG_X86_64_V4  # using -march=znver4 via KCFLAGS instead
./scripts/config --keep-case --disable CONFIG_X86_32
./scripts/config --keep-case --disable CONFIG_MAXSMP
./scripts/config --keep-case --enable  CONFIG_X86_MCE_AMD
./scripts/config --keep-case --disable CONFIG_X86_ANCIENT_MCE
./scripts/config --keep-case --enable  CONFIG_X86_X2APIC
./scripts/config --keep-case --enable  CONFIG_ACPI_PROCESSOR_IDLE
./scripts/config --keep-case --enable  CONFIG_CPU_IDLE_GOV_LADDER
./scripts/config --keep-case --enable  CONFIG_CPU_IDLE_GOV_MENU

# --- AMD platform / SMBus / GPIO ---------------------------------------------
./scripts/config --keep-case --enable CONFIG_AMD_NB
./scripts/config --keep-case --enable CONFIG_EDAC_DECODE_MCE
./scripts/config --keep-case --enable CONFIG_EDAC_AMD64
./scripts/config --keep-case --enable CONFIG_AMD_IOMMU
./scripts/config --keep-case --enable CONFIG_X86_AMD_PLATFORM_DEVICE
./scripts/config --keep-case --enable CONFIG_PINCTRL_AMD
./scripts/config --keep-case --module CONFIG_I2C_PIIX4    # AMD SMBus (als Modul)
./scripts/config --keep-case --module CONFIG_GPIO_AMD_FCH # GPIO (selten direkt gebraucht)

# --- AMD memory encryption (SME / SEV) ---------------------------------------
./scripts/config --keep-case --enable  CONFIG_AMD_MEM_ENCRYPT
./scripts/config --keep-case --disable CONFIG_AMD_MEM_ENCRYPT_ACTIVE_BY_DEFAULT

# --- CPU frequency scaling: AMD P-State + SCHEDUTIL -------------------------
./scripts/config --keep-case --enable CONFIG_CPU_FREQ
./scripts/config --keep-case --enable CONFIG_X86_AMD_PSTATE
./scripts/config --keep-case --enable CONFIG_CPU_FREQ_GOV_SCHEDUTIL
./scripts/config --keep-case --enable CONFIG_CPU_FREQ_GOV_PERFORMANCE
./scripts/config --keep-case --enable CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL
./scripts/config --keep-case --enable CONFIG_ENERGY_MODEL # feeds power cost data into SCHEDUTIL for smarter P-state decisions

# Disable all other default-governor options (only one can be default)
./scripts/config --keep-case --disable CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE
./scripts/config --keep-case --disable CONFIG_CPU_FREQ_DEFAULT_GOV_POWERSAVE
./scripts/config --keep-case --disable CONFIG_CPU_FREQ_DEFAULT_GOV_USERSPACE
./scripts/config --keep-case --disable CONFIG_CPU_FREQ_DEFAULT_GOV_ONDEMAND
./scripts/config --keep-case --disable CONFIG_CPU_FREQ_DEFAULT_GOV_CONSERVATIVE

# Remove unused governors entirely
./scripts/config --keep-case --disable CONFIG_CPU_FREQ_GOV_ONDEMAND
./scripts/config --keep-case --disable CONFIG_CPU_FREQ_GOV_CONSERVATIVE
./scripts/config --keep-case --disable CONFIG_CPU_FREQ_GOV_POWERSAVE
./scripts/config --keep-case --disable CONFIG_X86_ACPI_CPUFREQ # P-State replaces this

# --- Hardware monitoring (MSI X670E) -----------------------------------------
./scripts/config --keep-case --enable CONFIG_HWMON
./scripts/config --keep-case --module CONFIG_SENSORS_NCT6683      # Mainboard-Sensor (als Modul)
# NCT6687D is now handled by the nct6683 driver (CONFIG_SENSORS_NCT6683)
./scripts/config --keep-case --module CONFIG_SENSORS_K10TEMP      # Ryzen temp sensor (als Modul)
./scripts/config --keep-case --module CONFIG_SENSORS_FAM15H_POWER # Ryzen power sensor (als Modul)

# --- Crypto (AES-NI + AVX2 are present on Zen 4) ----------------------------
./scripts/config --keep-case --enable CONFIG_CRYPTO_AES_NI_INTEL
./scripts/config --keep-case --enable CONFIG_CRYPTO_AES
./scripts/config --keep-case --enable CONFIG_CRYPTO_XTS
./scripts/config --keep-case --enable CONFIG_CRYPTO_SHA256
./scripts/config --keep-case --module CONFIG_CRYPTO_USER_API_SKCIPHER
# CRYPTO_SHA256_SSSE3 was removed in 6.18 — the SSSE3/AVX/AVX2/SHA-NI x86 asm
# is now part of CRYPTO_LIB_SHA256 (auto-enabled on X86_64 via
# CRYPTO_LIB_SHA256_ARCH). CRYPTO_SHA256 selects it, so nothing to do here.

# --- ACPI --------------------------------------------------------------------
./scripts/config --keep-case --enable CONFIG_ACPI
#./scripts/config --keep-case --enable CONFIG_ACPI_AC
#./scripts/config --keep-case --enable CONFIG_ACPI_BATTERY
./scripts/config --keep-case --enable CONFIG_ACPI_BUTTON

# --- PCIe (X670E: PCIe 5.0 host) ---------------------------------------------
./scripts/config --keep-case --enable CONFIG_PCIEAER
./scripts/config --keep-case --enable CONFIG_PCIEPORTBUS
#./scripts/config --keep-case --disable CONFIG_PCIEASPM

# --- Memory: 64 GB DDR5 -----------------------------------------------------
./scripts/config --keep-case --enable  CONFIG_TRANSPARENT_HUGEPAGE
./scripts/config --keep-case --disable CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS
./scripts/config --keep-case --enable  CONFIG_TRANSPARENT_HUGEPAGE_MADVISE # mutually exclusive with ALWAYS
./scripts/config --keep-case --enable  CONFIG_COMPACTION
./scripts/config --keep-case --enable  CONFIG_MIGRATION
./scripts/config --keep-case --disable CONFIG_KSM # 64 GB = no need to deduplicate pages
./scripts/config --keep-case --enable  CONFIG_NUMA_BALANCING
./scripts/config --keep-case --enable  CONFIG_NUMA_BALANCING_DEFAULT_ENABLED

# --- GPU: NVIDIA 3070 only – disable everything else ------------------------
./scripts/config --keep-case --enable CONFIG_DRM
./scripts/config --keep-case --enable CONFIG_DRM_SIMPLEDRM # EFI boot frame buffer before NVIDIA inits
./scripts/config --keep-case --enable CONFIG_DRM_FBDEV_EMULATION
# === NVIDIA-only: Force disable nouveau completely (LLVM LTO fix) ===
./scripts/config --keep-case --disable CONFIG_DRM_NOUVEAU
./scripts/config --keep-case --disable CONFIG_NOUVEAU_PLATFORM_DRIVER
./scripts/config --keep-case --disable CONFIG_DRM_NOUVEAU_BACKLIGHT

# Framebuffer
./scripts/config --keep-case --enable CONFIG_FB
./scripts/config --keep-case --enable CONFIG_FB_EFI
./scripts/config --keep-case --enable CONFIG_FB_VESA
./scripts/config --keep-case --disable CONFIG_FB_NVIDIA # proprietary driver handles this

# AMD GPU drivers – not needed (disabled in BIOS)
./scripts/config --keep-case --disable CONFIG_DRM_AMDGPU
./scripts/config --keep-case --disable CONFIG_DRM_AMDGPU_CIK
./scripts/config --keep-case --disable CONFIG_DRM_AMDGPU_SI
./scripts/config --keep-case --disable CONFIG_DRM_RADEON

# Other unused GPU / accelerator drivers
./scripts/config --keep-case --disable CONFIG_DRM_I915
./scripts/config --keep-case --disable CONFIG_DRM_XE
./scripts/config --keep-case --disable CONFIG_DRM_VMWGFX
./scripts/config --keep-case --disable CONFIG_DRM_QXL
./scripts/config --keep-case --disable CONFIG_DRM_VIRTIO_GPU
./scripts/config --keep-case --disable CONFIG_DRM_BOCHS
./scripts/config --keep-case --disable CONFIG_DRM_CIRRUS_QEMU
./scripts/config --keep-case --disable CONFIG_DRM_VGEM
./scripts/config --keep-case --disable CONFIG_DRM_VKMS
./scripts/config --keep-case --disable CONFIG_DRM_UDL
./scripts/config --keep-case --disable CONFIG_DRM_AST
./scripts/config --keep-case --disable CONFIG_DRM_MGAG200
./scripts/config --keep-case --disable CONFIG_DRM_GMA500
./scripts/config --keep-case --disable CONFIG_DRM_ACCEL_HABANALABS
./scripts/config --keep-case --disable CONFIG_DRM_ACCEL_IVPU
./scripts/config --keep-case --disable CONFIG_DRM_ACCEL_QAIC
./scripts/config --keep-case --disable CONFIG_DRM_ACCEL_AMDXDNA

# --- Sound: Realtek ALC4080 via HD Audio controller – no HDMI audio --------
./scripts/config --keep-case --module  CONFIG_SND_HDA_INTEL
./scripts/config --keep-case --module  CONFIG_SND_HDA_CODEC_REALTEK
./scripts/config --keep-case --module  CONFIG_SND_HDA_GENERIC       # renamed from SND_HDA_CODEC_GENERIC in 6.18

# Disable all unused HDA codecs and HDMI audio
for c in ANALOG SIGMATEL VIA CONEXANT SENARYTECH CA0110 CA0132 CMEDIA CM9825 \
  SI3054 CIRRUS CS420X CS421X CS8409 \
  HDMI HDMI_GENERIC HDMI_SIMPLE HDMI_INTEL HDMI_ATI HDMI_NVIDIA \
  HDMI_NVIDIA_MCP HDMI_TEGRA; do
  ./scripts/config --keep-case --disable "CONFIG_SND_HDA_CODEC_${c}"
done
./scripts/config --keep-case --disable CONFIG_SND_HDA_INTEL_HDMI_SILENT_STREAM
./scripts/config --keep-case --disable CONFIG_SOUND_HDA_CODEC_HDMI

# Disable entire Intel SOC audio stack (not needed on AMD)
./scripts/config --keep-case --disable CONFIG_SND_SOC_INTEL_SST_TOPLEVEL
# lets make SND_SOC_INTEL_SOF_DA7219_MACH m -> n explicit
./scripts/config --keep-case --disable CONFIG_SND_SOC_INTEL_SOF_DA7219_MACH

# PipeWire / PulseAudio basics
./scripts/config --keep-case --module CONFIG_SND_TIMER
./scripts/config --keep-case --module CONFIG_SND_PCM

# --- USB ---------------------------------------------------------------------
./scripts/config --keep-case --enable CONFIG_USB_SUPPORT
./scripts/config --keep-case --enable CONFIG_USB_STORAGE
./scripts/config --keep-case --enable CONFIG_USB_XHCI_HCD
./scripts/config --keep-case --module CONFIG_USB_PRINTER
./scripts/config --keep-case --module CONFIG_USB_EHCI_HCD # USB 2.0; some internal headers may bypass xHCI

# --- Input -------------------------------------------------------------------
./scripts/config --keep-case --enable CONFIG_INPUT_EVDEV
./scripts/config --keep-case --module CONFIG_HID_GENERIC
./scripts/config --keep-case --module CONFIG_USB_HID
./scripts/config --keep-case --module CONFIG_MMC_BLOCK
./scripts/config --keep-case --module CONFIG_MMC_SDHCI_PCI    # PCI SDHC Host

# No game controllers on this system
./scripts/config --keep-case --disable CONFIG_INPUT_JOYDEV
./scripts/config --keep-case --disable CONFIG_JOYSTICK_XPAD   # Xbox Controller
./scripts/config --keep-case --disable CONFIG_HID_PLAYSTATION # PS5 Controller
./scripts/config --keep-case --disable CONFIG_HID_STEAM       # Steam Controller

# --- Network: Realtek 2.5GbE – no WiFi --------------------------
./scripts/config --keep-case --enable CONFIG_INET
./scripts/config --keep-case --enable CONFIG_IPV6
./scripts/config --keep-case --enable CONFIG_NET_VENDOR_REALTEK
./scripts/config --keep-case --enable CONFIG_R8169 # ← Mainline Driver (RTL8125 ✓)
./scripts/config --keep-case --enable CONFIG_R8169_LEDS
./scripts/config --keep-case --disable CONFIG_R8125 # ← Realtek OOT Driver

# Disable WiFi stack entirely
./scripts/config --keep-case --disable CONFIG_WIRELESS
./scripts/config --keep-case --disable CONFIG_WLAN
./scripts/config --keep-case --disable CONFIG_CFG80211
./scripts/config --keep-case --disable CONFIG_MAC80211
./scripts/config --keep-case --disable CONFIG_IWLWIFI
./scripts/config --keep-case --disable CONFIG_ATH9K
./scripts/config --keep-case --disable CONFIG_ATH11K
./scripts/config --keep-case --disable CONFIG_RT2X00
./scripts/config --keep-case --disable CONFIG_MT76

# Bluetooth – benötigt auf diesem System
./scripts/config --keep-case --module CONFIG_BT          # Als Modul (wird nur bei Bedarf geladen)
./scripts/config --keep-case --module CONFIG_BT_RFCOMM   # Serial-Profil (z. B. Tastatur)
./scripts/config --keep-case --module CONFIG_BT_HIDP     # HID over Bluetooth — needed for BT headsets
./scripts/config --keep-case --module CONFIG_BT_BNEP     # Network profile
./scripts/config --keep-case --module CONFIG_BT_HCIBTUSB # USB Bluetooth adapter
./scripts/config --keep-case --enable CONFIG_BT_LE       # Bluetooth Low Energy

# All other NIC vendors
for v in INTEL 3COM ADAPTEC ADI ALACRITECH AGERE ALTEON AMAZON AMD AQUANTIA ARC ASIX ATHEROS \
  BROADCOM BROCADE CADENCE CAVIUM CHELSIO CISCO CORTINA DAVICOM DEC DLINK EMULEX ENGLEDER \
  EZCHIP FUNGIBLE GOOGLE HUAWEI LITEX MARVELL MELLANOX META MICREL MICROCHIP MICROSEMI MICROSOFT \
  MYRICOM NATSEMI NETERION NETRONOME NI NVIDIA OKI PACKET_ENGINES PENSANDO \
  QLOGIC QUALCOMM RENESAS RDC ROCKER SAMSUNG SEEQ SILAN SIS SMSC SOLARFLARE SOCIONEXT STMICRO \
  SUN SYNOPSYS TEHUTI TI WANGXUN VERTEXCOM VIA WIZNET XILINX; do
  ./scripts/config --keep-case --disable "CONFIG_NET_VENDOR_${v}"
done

# --- Network performance: BBR + FQ + Cake ------------------------------------
./scripts/config --keep-case --enable CONFIG_NET_SCH_FQ
./scripts/config --keep-case --enable CONFIG_NET_SCH_FQ_CODEL
./scripts/config --keep-case --enable CONFIG_NET_SCH_CAKE
./scripts/config --keep-case --enable CONFIG_DEFAULT_BBR
./scripts/config --keep-case --enable CONFIG_TCP_CONG_BBR
./scripts/config --keep-case --set-str CONFIG_DEFAULT_TCP_CONG "bbr"
./scripts/config --keep-case --disable CONFIG_DEFAULT_CUBIC

# --- Storage: NVMe -----------------------------------------------------------
./scripts/config --keep-case --enable CONFIG_NVME_CORE
./scripts/config --keep-case --enable CONFIG_BLK_DEV_NVME
./scripts/config --keep-case --enable CONFIG_NVME_MULTIPATH
./scripts/config --keep-case --enable CONFIG_NVME_HWMON

# SATA für deine zusätzlichen SSDs/HDD
./scripts/config --keep-case --enable CONFIG_SATA_AHCI
./scripts/config --keep-case --enable CONFIG_ATA

# SCSI Layer (für SATA)
./scripts/config --keep-case --enable CONFIG_SCSI
./scripts/config --keep-case --enable CONFIG_BLK_DEV_SD
./scripts/config --keep-case --enable CONFIG_BLK_DEV_SR # CD/DVD

# --- I/O scheduler: BFQ (good for mixed read/write desktop workloads) -------
./scripts/config --keep-case --enable CONFIG_MQ_IOSCHED_DEADLINE
./scripts/config --keep-case --enable CONFIG_IOSCHED_BFQ
./scripts/config --keep-case --enable CONFIG_BFQ_GROUP_IOSCHED
# DEFAULT_IOSCHED was removed in 6.18 — the kernel now hardcodes mq-deadline
# for single-queue and "none" for multi-queue devices (block/elevator.c).
# udev assigns BFQ to rotational devices at runtime.

# --- Filesystems -------------------------------------------------------------
./scripts/config --keep-case --enable CONFIG_EXT4_FS
./scripts/config --keep-case --enable CONFIG_BTRFS_FS
./scripts/config --keep-case --module CONFIG_CIFS
./scripts/config --keep-case --enable CONFIG_VFAT_FS    # ESP
./scripts/config --keep-case --enable CONFIG_NTFS3_FS   # modern NTFS driver
./scripts/config --keep-case --enable CONFIG_FUSE_FS    # AppImage etc.
./scripts/config --keep-case --enable CONFIG_OVERLAY_FS # Flatpak / Snap / containers
./scripts/config --keep-case --enable CONFIG_TMPFS
./scripts/config --keep-case --enable CONFIG_PROC_FS
./scripts/config --keep-case --enable CONFIG_SYSFS
./scripts/config --keep-case --module CONFIG_EXFAT_FS
./scripts/config --keep-case --enable CONFIG_ISO9660_FS
./scripts/config --keep-case --enable CONFIG_UDF_FS
./scripts/config --keep-case --module CONFIG_F2FS_FS

# Exotic – not needed
./scripts/config --keep-case --disable CONFIG_REISERFS_FS
./scripts/config --keep-case --disable CONFIG_JFS_FS
./scripts/config --keep-case --disable CONFIG_NILFS2_FS
./scripts/config --keep-case --disable CONFIG_EROFS_FS
./scripts/config --keep-case --disable CONFIG_XFS_FS

# --- Containers / Flatpak / Snap (Mint) --------------------------------------
./scripts/config --keep-case --enable CONFIG_USER_NS
./scripts/config --keep-case --enable CONFIG_CGROUPS
./scripts/config --keep-case --enable CONFIG_NAMESPACES

# --- Security: AppArmor (Mint default) – no SELinux -------------------------
./scripts/config --keep-case --enable  CONFIG_SECURITY_APPARMOR
./scripts/config --keep-case --enable  CONFIG_DEFAULT_SECURITY_APPARMOR
./scripts/config --keep-case --disable CONFIG_SECURITY_SELINUX
# ../scripts/config --keep-case --disable CONFIG_RETPOLINE
# ../scripts/config --keep-case --disable CONFIG_CPU_SPEC_STORE_BYPASS_DISABLE
# ../scripts/config --keep-case --disable CONFIG_PAGE_TABLE_ISOLATION
# ../scripts/config --keep-case --disable CONFIG_SECURITY_SMACK
# ../scripts/config --keep-case --disable CONFIG_IMA

# --- VFIO (GPU passthrough / isolation) --------------------------------------
./scripts/config --keep-case --module CONFIG_VFIO     # Als Modul (nur bei Bedarf für VMs)
./scripts/config --keep-case --module CONFIG_VFIO_PCI # Als Modul

# --- Unused subsystems -------------------------------------------------------
./scripts/config --keep-case --disable CONFIG_HAMRADIO
./scripts/config --keep-case --disable CONFIG_CAN
./scripts/config --keep-case --disable CONFIG_NFC
./scripts/config --keep-case --disable CONFIG_WIMAX
./scripts/config --keep-case --disable CONFIG_PCMCIA
./scripts/config --keep-case --disable CONFIG_FIREWIRE
./scripts/config --keep-case --disable CONFIG_INFINIBAND
./scripts/config --keep-case --disable CONFIG_PHONE
./scripts/config --keep-case --disable CONFIG_ARCNET
./scripts/config --keep-case --disable CONFIG_ISDN
./scripts/config --keep-case --disable CONFIG_PARPORT
./scripts/config --keep-case --disable CONFIG_BLK_DEV_FD # floppy
./scripts/config --keep-case --disable CONFIG_ATM        # legacy ATM/DSL networking
./scripts/config --keep-case --disable CONFIG_STAGING    # experimental/niche drivers (fbtft, greybus, gpib, …)

# --- Virtualization guests: bare-metal desktop, no hypervisor ----------------
./scripts/config --keep-case --disable CONFIG_XEN
./scripts/config --keep-case --disable CONFIG_XEN_PV
./scripts/config --keep-case --disable CONFIG_XEN_PVHVM
./scripts/config --keep-case --disable CONFIG_XEN_512GB
./scripts/config --keep-case --disable CONFIG_XEN_SAVE_RESTORE
./scripts/config --keep-case --disable CONFIG_XEN_BALLOON
./scripts/config --keep-case --disable CONFIG_XEN_DEV_EVTCHN
./scripts/config --keep-case --disable CONFIG_XEN_BACKEND
./scripts/config --keep-case --disable CONFIG_XEN_BLKDEV_FRONTEND
./scripts/config --keep-case --disable CONFIG_XEN_NETDEV_FRONTEND
./scripts/config --keep-case --disable CONFIG_XEN_PCIDEV_FRONTEND
./scripts/config --keep-case --disable CONFIG_HYPERV
./scripts/config --keep-case --disable CONFIG_HYPERV_UTILS
./scripts/config --keep-case --disable CONFIG_HYPERV_BALLOON

# --- SCSI HBA drivers: keep core SCSI (sd/sr/sg) but drop FC/SAS adapters ---
./scripts/config --keep-case --disable CONFIG_SCSI_QLA_FC        # QLogic Fibre Channel
./scripts/config --keep-case --disable CONFIG_SCSI_QLA_ISCSI     # QLogic iSCSI
./scripts/config --keep-case --disable CONFIG_SCSI_LPFC          # Emulex/Broadcom FC
./scripts/config --keep-case --disable CONFIG_SCSI_BFA_FC        # Brocade FC
./scripts/config --keep-case --disable CONFIG_SCSI_FNIC          # Cisco FCoE
./scripts/config --keep-case --disable CONFIG_SCSI_SNIC          # Cisco SCSI
./scripts/config --keep-case --disable CONFIG_SCSI_AIC7XXX       # Adaptec AIC-7xxx
./scripts/config --keep-case --disable CONFIG_SCSI_AIC79XX       # Adaptec AIC-79xx
./scripts/config --keep-case --disable CONFIG_SCSI_AIC94XX       # Adaptec AIC-94xx SAS
./scripts/config --keep-case --disable CONFIG_SCSI_MVSAS         # Marvell SAS
./scripts/config --keep-case --disable CONFIG_SCSI_MVUMI         # Marvell UMI
./scripts/config --keep-case --disable CONFIG_MEGARAID_SAS       # LSI MegaRAID SAS
./scripts/config --keep-case --disable CONFIG_MEGARAID_LEGACY    # legacy MegaRAID
./scripts/config --keep-case --disable CONFIG_MEGARAID_NEWGEN    # MegaRAID new-gen
./scripts/config --keep-case --disable CONFIG_MEGARAID_MM        # MegaRAID management
./scripts/config --keep-case --disable CONFIG_MEGARAID_MAILBOX   # MegaRAID mailbox
./scripts/config --keep-case --disable CONFIG_SCSI_MPT3SAS       # Broadcom MPT SAS
./scripts/config --keep-case --disable CONFIG_SCSI_MPT2SAS       # Broadcom MPT SAS v2
./scripts/config --keep-case --disable CONFIG_SCSI_AACRAID       # Adaptec AACRAID
./scripts/config --keep-case --disable CONFIG_SCSI_HPSA          # HP Smart Array
./scripts/config --keep-case --disable CONFIG_SCSI_SMARTPQI      # Microsemi SmartPQI
./scripts/config --keep-case --disable CONFIG_SCSI_PM8001        # PMC-Sierra SAS
./scripts/config --keep-case --disable CONFIG_SCSI_ISCI          # Intel C600 SAS
./scripts/config --keep-case --disable CONFIG_SCSI_ESAS2R        # ATTO ExpressSAS
./scripts/config --keep-case --disable CONFIG_SCSI_BNX2_ISCSI    # Broadcom NetXtreme iSCSI
./scripts/config --keep-case --disable CONFIG_SCSI_BNX2X_FCOE   # Broadcom FCoE
./scripts/config --keep-case --disable CONFIG_SCSI_CXGB3_ISCSI  # Chelsio T3 iSCSI
./scripts/config --keep-case --disable CONFIG_SCSI_CXGB4_ISCSI  # Chelsio T4 iSCSI
./scripts/config --keep-case --disable CONFIG_SCSI_CSIOSTOR      # Chelsio FCoE
./scripts/config --keep-case --disable CONFIG_SCSI_VIRTIO        # virtio SCSI

# --- Media: keep UVC webcam only, disable TV/DVB/radio/IR/gspca -------------
./scripts/config --keep-case --disable CONFIG_MEDIA_ANALOG_TV_SUPPORT
./scripts/config --keep-case --disable CONFIG_MEDIA_DIGITAL_TV_SUPPORT
./scripts/config --keep-case --disable CONFIG_MEDIA_RADIO_SUPPORT
./scripts/config --keep-case --disable CONFIG_MEDIA_SDR_SUPPORT
./scripts/config --keep-case --disable CONFIG_MEDIA_PLATFORM_SUPPORT
./scripts/config --keep-case --disable CONFIG_MEDIA_TEST_SUPPORT
./scripts/config --keep-case --disable CONFIG_MEDIA_PCI_SUPPORT     # all PCI TV tuners
./scripts/config --keep-case --disable CONFIG_VIDEO_IR_I2C           # IR over I2C
./scripts/config --keep-case --disable CONFIG_RC_CORE                # IR remote controls
./scripts/config --keep-case --disable CONFIG_RC_MAP                 # IR keymaps
./scripts/config --keep-case --disable CONFIG_LIRC                   # legacy IR
./scripts/config --keep-case --disable CONFIG_USB_GSPCA              # ancient USB webcams
./scripts/config --keep-case --disable CONFIG_DVB_CORE               # digital TV core
# Keep CONFIG_MEDIA_USB_SUPPORT=y and CONFIG_USB_VIDEO_CLASS=m (UVC webcam)

# --- Input: disable touchscreen drivers (desktop system) ---------------------
./scripts/config --keep-case --disable CONFIG_INPUT_TOUCHSCREEN

# --- Watchdog: disable all hardware watchdogs (desktop, not server) ----------
./scripts/config --keep-case --disable CONFIG_WATCHDOG

# --- Crypto HW: disable non-AMD accelerators --------------------------------
# Rules for this section:
# 1. Hidden tristates (QAT, NITROX) are selected by children — disable every
#    child so nothing can select the parent back on.
# 2. When a parent's children use `select PARENT`, also list the children
#    explicitly (e.g. PADLOCK_AES/SHA, ATMEL_I2C) so a different base config
#    cannot leave them enabled while the parent appears disabled.
# 3. Drivers in other subsystems that depend on disabled crypto drivers must
#    also be listed explicitly (e.g. QAT_VFIO_PCI depends on QAT_4XXX).
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_QAT           # Intel QuickAssist (hidden, selected by children)
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_QAT_DH895xCC  # Intel QAT DH895x
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_QAT_C3XXX     # Intel QAT C3xxx
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_QAT_C62X      # Intel QAT C62x
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_QAT_4XXX      # Intel QAT gen4
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_QAT_420XX     # Intel QAT 420xx
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_QAT_6XXX      # Intel QAT 6xxx (new in 6.18)
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_QAT_DH895xCCVF # Intel QAT DH895x VF
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_QAT_C3XXXVF   # Intel QAT C3xxx VF
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_QAT_C62XVF    # Intel QAT C62x VF
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_QAT_ERROR_INJECTION  # Intel QAT error injection (testing)
./scripts/config --keep-case --disable CONFIG_QAT_VFIO_PCI             # QAT VFIO migration driver (depends on QAT_4XXX; different subsystem)
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_CAVIUM_ZIP    # Cavium ZIP
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_NITROX        # Cavium Nitrox (hidden, selected by child)
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_NITROX_CNN55XX # Cavium CNN55XX (the only child)
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_CHELSIO       # Chelsio crypto
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_VIRTIO        # virtio crypto
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_AMLOGIC_GXL   # Amlogic SoC
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_INSIDE_SECURE  # Inside Secure
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_PADLOCK        # VIA PadLock (parent)
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_PADLOCK_AES   # VIA PadLock AES (child)
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_PADLOCK_SHA   # VIA PadLock SHA (child)
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_ATMEL_I2C     # Atmel I2C crypto lib (selected by ATMEL_ECC / ATMEL_SHA204A)
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_ATMEL_ECC     # Atmel ATECC
./scripts/config --keep-case --disable CONFIG_CRYPTO_DEV_ATMEL_SHA204A # Atmel SHA204A

# --- Platform: disable laptop/embedded/server platform drivers ---------------
./scripts/config --keep-case --disable CONFIG_CHROME_PLATFORMS       # ChromeOS
./scripts/config --keep-case --disable CONFIG_SURFACE_PLATFORMS      # Microsoft Surface
./scripts/config --keep-case --disable CONFIG_MELLANOX_PLATFORM      # Mellanox switches

# --- Filesystems: disable cluster/network/niche FS --------------------------
./scripts/config --keep-case --disable CONFIG_OCFS2_FS       # Oracle Cluster FS
./scripts/config --keep-case --disable CONFIG_GFS2_FS        # Red Hat Cluster FS
./scripts/config --keep-case --disable CONFIG_CEPH_FS        # Ceph distributed FS
./scripts/config --keep-case --disable CONFIG_ORANGEFS_FS    # OrangeFS parallel FS
./scripts/config --keep-case --disable CONFIG_AFS_FS         # Andrew File System
./scripts/config --keep-case --disable CONFIG_9P_FS          # Plan 9 / QEMU 9P
./scripts/config --keep-case --disable CONFIG_CODA_FS        # Coda network FS
./scripts/config --keep-case --disable CONFIG_HFS_FS         # Apple HFS
./scripts/config --keep-case --disable CONFIG_HFSPLUS_FS     # Apple HFS+
./scripts/config --keep-case --disable CONFIG_MINIX_FS       # Minix
./scripts/config --keep-case --disable CONFIG_ROMFS_FS       # ROM filesystem
./scripts/config --keep-case --disable CONFIG_CRAMFS         # Compressed ROM FS
./scripts/config --keep-case --disable CONFIG_UFS_FS         # BSD UFS

# --- network protocols ------------------------------------------------
./scripts/config --keep-case --enable  CONFIG_WIREGUARD
./scripts/config --keep-case --disable CONFIG_IPX
./scripts/config --keep-case --disable CONFIG_ATALK
./scripts/config --keep-case --disable CONFIG_X25
./scripts/config --keep-case --disable CONFIG_DECNET

# --- Faster boot -------------------------------------------------------------
./scripts/config --keep-case --disable CONFIG_PRINTK_TIME
./scripts/config --keep-case --disable CONFIG_BOOT_PRINTK_DELAY

# --- Debug / tracing: all off for production ---------------------------------
./scripts/config --keep-case --enable  CONFIG_DEBUG_INFO_NONE
./scripts/config --keep-case --disable CONFIG_MODVERSIONS
./scripts/config --keep-case --disable CONFIG_ASM_MODVERSIONS
./scripts/config --keep-case --disable CONFIG_EXTENDED_MODVERSIONS
./scripts/config --keep-case --disable CONFIG_BASIC_MODVERSIONS
./scripts/config --keep-case --disable CONFIG_GENKSYMS
./scripts/config --keep-case --disable CONFIG_FTRACE
./scripts/config --keep-case --disable CONFIG_KPROBES
./scripts/config --keep-case --disable CONFIG_LIVEPATCH
./scripts/config --keep-case --disable CONFIG_DEBUG_INFO_BTF
./scripts/config --keep-case --disable CONFIG_DEBUG_INFO
./scripts/config --keep-case --disable CONFIG_DEBUG_INFO_DWARF4
./scripts/config --keep-case --disable CONFIG_DEBUG_INFO_DWARF5
./scripts/config --keep-case --disable CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
./scripts/config --keep-case --disable CONFIG_DEBUG_KMAP_LOCAL_FORCE_MAP
./scripts/config --keep-case --disable CONFIG_DEBUG_CGROUP_REF
./scripts/config --keep-case --disable CONFIG_DEBUG_OBJECTS
./scripts/config --keep-case --disable CONFIG_KCOV
./scripts/config --keep-case --disable CONFIG_PROVE_LOCKING
./scripts/config --keep-case --disable CONFIG_LOCK_STAT
./scripts/config --keep-case --disable CONFIG_KGDB
./scripts/config --keep-case --disable CONFIG_UBSAN
./scripts/config --keep-case --disable CONFIG_KASAN
./scripts/config --keep-case --disable CONFIG_PAGE_OWNER
./scripts/config --keep-case --disable CONFIG_DRM_DEBUG_DP_MST_TOPOLOGY_REFS
./scripts/config --keep-case --disable CONFIG_DRM_DEBUG_MODESET_LOCK
./scripts/config --keep-case --disable CONFIG_DRM_PANIC_DEBUG
./scripts/config --keep-case --disable CONFIG_KPROBE_EVENTS
./scripts/config --keep-case --disable CONFIG_SAMPLE_KPROBES
./scripts/config --keep-case --disable CONFIG_FUNCTION_ERROR_INJECTION

# --- Module signing: clear keys (custom build, not distro-signed) -----------
./scripts/config --keep-case --set-str CONFIG_SYSTEM_REVOCATION_KEYS ""
./scripts/config --keep-case --set-str CONFIG_SYSTEM_TRUSTED_KEYS ""
#./scripts/config --keep-case --disable MODULE_SIG
./scripts/config --keep-case --disable CONFIG_MODULE_SIG_ALL
