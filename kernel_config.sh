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
#   SSD:       Samsung 970 EVO Plus 1 TB (NVMe PCIe 3.0 x4)
#   HDD:       Western Digital WD Caviar Green 1TB
#   SSD2:      Lexar NM620 1TB
#   SSD3:      Samsung SSD 850 EVO 500GB
#   GPU:       NVIDIA GeForce RTX 3070 (AMD GPU disabled in BIOS)
#   Sound:     Onboard (Realtek via HDA Intel) – no HDMI audio
#   Network:   Realtek RTL8125 2.5GbE onboard – WiFi unused, Bluetooth used
#   OS:        Linux Mint 22.3
# External Hardware 
#   Keyboard:       Logitech MX Keys (USB receiver)
#   Mouse:          Asus ROG Keris Wireless Aimpoint (USB receiver)
#   Monitor:        Dell U2715H
#   DVD-Writer:     TSSTcorp SH-S203D
#   Printer:        Color Laser Jet Pro MFP M477fdn
#   SDCard Reader:  Lexar USB 3.0 LRW400U Rev A (connected via USB)
#   SD Card Reader: Graugear G-MP01CR
#   HeadSet:        BeyerDynamic MMX 200
#   Smartphone:     Samsung S20FE
# ==============================================================================

# --- Compiler & LTO ----------------------------------------------------------
./scripts/config --enable  CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE   # -O2
./scripts/config --disable CONFIG_GCC_PLUGINS                   # unused, saves compile time
./scripts/config --enable  CONFIG_LTO_GCC
./scripts/config --enable  CONFIG_LTO
./scripts/config --disable CONFIG_CC_OPTIMIZE_FOR_SIZE
./scripts/config --disable CONFIG_LTO_CLANG

# --- Module compression (zstd is faster than gzip on modern CPUs) ------------
./scripts/config --enable  CONFIG_MODULE_COMPRESS_ZSTD
./scripts/config --disable CONFIG_MODULE_COMPRESS_GZIP
# --- Firmware with zstd compression support ----------------------------------
./scripts/config --enable CONFIG_FW_LOADER
./scripts/config --enable CONFIG_FW_LOADER_COMPRESS
./scripts/config --enable CONFIG_FW_LOADER_COMPRESS_ZSTD
./scripts/config --enable CONFIG_FW_LOADER_USER_HELPER
./scripts/config --enable CONFIG_FW_LOADER_COMPRESS
./scripts/config --enable CONFIG_FW_LOADER_COMPRESS_ZSTD

# --- Swap compression (zswap) ------------------------------------------------
./scripts/config --enable  CONFIG_ZSWAP
./scripts/config --enable  CONFIG_ZSWAP_DEFAULT_ON
./scripts/config --set-str CONFIG_ZSWAP_COMPRESSOR_DEFAULT "zstd"
./scripts/config --set-str CONFIG_ZSWAP_FRONTSWAP_SHRINKER_DEFAULT "yes"

# --- Initramfs (required by Mint) --------------------------------------------
./scripts/config --enable CONFIG_BLK_DEV_INITRD
./scripts/config --enable CONFIG_RD_GZIP
./scripts/config --enable CONFIG_RD_ZSTD

# --- Timer & scheduling ------------------------------------------------------
#./scripts/config --enable  CONFIG_HZ_PERIODIC
#./scripts/config --disable CONFIG_NO_HZ_FULL
./scripts/config --disable CONFIG_HZ_PERIODIC
./scripts/config --enable CONFIG_NO_HZ_IDLE        # Better for desktop
./scripts/config --enable CONFIG_NO_HZ_FULL        # For CPU isolation if needed
./scripts/config --enable  CONFIG_TICK_CPU_ACCOUNTING
./scripts/config --disable CONFIG_VIRT_CPU_ACCOUNTING_GEN
./scripts/config --disable CONFIG_NTP_PPS                       # desktop doesn't need PPS
./scripts/config --disable CONFIG_SCHED_CORE_SCHED
./scripts/config --set-val CONFIG_RCU_BOOST_DELAY 500
#./scripts/config --enable  CONFIG_RCU_NOCB_CPU # GRUB -rcu_nocbs=0-31

# --- Preemption (dynamic = best of both worlds on desktop) ------------------
./scripts/config --enable  CONFIG_PREEMPT_DYNAMIC
./scripts/config --disable CONFIG_PREEMPT_VOLUNTARY
./scripts/config --disable CONFIG_PREEMPT_NONE

# --- Timer frequency: 1000 Hz for smooth desktop ----------------------------
./scripts/config --disable CONFIG_HZ_250
./scripts/config --disable CONFIG_HZ_500
./scripts/config --enable  CONFIG_HZ_1000
./scripts/config --set-val CONFIG_HZ 1000

# --- CPU: AMD Zen 4 / Ryzen 9 7950X3D ---------------------------------------
./scripts/config --enable CONFIG_AMD_X3D_OPTIMIZER
./scripts/config --enable CONFIG_SCHED_MC_PRIO
./scripts/config --enable  CONFIG_SCHED_MC
./scripts/config --enable  CONFIG_SCHED_SMT
./scripts/config --enable  CONFIG_CPU_SUP_AMD
./scripts/config --disable CONFIG_GENERIC_CPU
./scripts/config --disable CONFIG_CPU_SUP_INTEL
./scripts/config --disable CONFIG_CPU_SUP_CENTAUR
./scripts/config --disable CONFIG_CPU_SUP_ZHAOXIN
./scripts/config --set-val CONFIG_NR_CPUS 32                    # 16 cores / 32 threads
./scripts/config --disable CONFIG_X86_64_V4
./scripts/config --enable  CONFIG_X86_64_V3                     # AVX-512 (Zen 4<) 
./scripts/config --enable  CONFIG_X86_32
./scripts/config --disable CONFIG_MAXSMP
./scripts/config --enable  CONFIG_X86_MCE_AMD
./scripts/config --disable CONFIG_X86_ANCIENT_MCE
./scripts/config --enable  CONFIG_X86_X2APIC^
./scripts/config --enable  CONFIG_HAVE_PERF_EVENTS_NMI
./scripts/config --enable CONFIG_ACPI_PROCESSOR_IDLE
./scripts/config --enable CONFIG_CPU_IDLE_GOV_LADDER
./scripts/config --enable CONFIG_CPU_IDLE_GOV_MENU

# --- AMD platform / SMBus / GPIO ---------------------------------------------
./scripts/config --enable CONFIG_AMD_NB
./scripts/config --enable CONFIG_EDAC_DECODE_MCE
./scripts/config --enable CONFIG_EDAC_AMD64
./scripts/config --enable CONFIG_AMD_IOMMU
./scripts/config --enable CONFIG_AMD_IOMMU_V2
./scripts/config --enable CONFIG_X86_AMD_PLATFORM_DEVICE
./scripts/config --enable CONFIG_PINCTRL_AMD
./scripts/config --module CONFIG_I2C_PIIX4                      # AMD SMBus (als Modul)
./scripts/config --module CONFIG_GPIO_AMD_FCH                   # GPIO (selten direkt gebraucht)

# --- AMD memory encryption (SME / SEV) ---------------------------------------
./scripts/config --enable  CONFIG_AMD_MEM_ENCRYPT
./scripts/config --disable CONFIG_AMD_MEM_ENCRYPT_ACTIVE_BY_DEFAULT

# --- CPU frequency scaling: AMD P-State + SCHEDUTIL -------------------------
./scripts/config --enable  CONFIG_CPU_FREQ
./scripts/config --enable  CONFIG_X86_AMD_PSTATE
#../scripts/config --enable CONFIG_X86_AMD_PSTATE_UT     # Optional: Unit Tests
./scripts/config --enable  CONFIG_CPU_FREQ_GOV_SCHEDUTIL
./scripts/config --enable  CONFIG_CPU_FREQ_GOV_PERFORMANCE
./scripts/config --enable  CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL

# Disable all other default-governor options (only one can be default)
./scripts/config --disable CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE
./scripts/config --disable CONFIG_CPU_FREQ_DEFAULT_GOV_POWERSAVE
./scripts/config --disable CONFIG_CPU_FREQ_DEFAULT_GOV_USERSPACE
./scripts/config --disable CONFIG_CPU_FREQ_DEFAULT_GOV_ONDEMAND
./scripts/config --disable CONFIG_CPU_FREQ_DEFAULT_GOV_CONSERVATIVE

# Remove unused governors entirely
./scripts/config --disable CONFIG_CPU_FREQ_GOV_ONDEMAND
./scripts/config --disable CONFIG_CPU_FREQ_GOV_CONSERVATIVE
./scripts/config --disable CONFIG_CPU_FREQ_GOV_POWERSAVE
./scripts/config --disable CONFIG_X86_ACPI_CPUFREQ              # P-State replaces this

# --- Hardware monitoring (MSI X670E) -----------------------------------------
./scripts/config --enable CONFIG_HWMON
./scripts/config --module CONFIG_NCT6683                        # Mainboard-Sensor (als Modul)
./scripts/config --module CONFIG_SENSORS_NCT6687                # Mainboard-Sensor (als Modul)
./scripts/config --module CONFIG_SENSORS_K10TEMP                # Ryzen temp sensor (als Modul)
./scripts/config --module CONFIG_SENSORS_FAM15H_POWER           # Ryzen power sensor (als Modul)

# --- Crypto (AES-NI + AVX2 are present on Zen 4) ----------------------------
./scripts/config --enable CONFIG_CRYPTO_AES_NI_INTEL
./scripts/config --enable CONFIG_CRYPTO_AVX2
./scripts/config --enable CONFIG_CRYPTO_SHA256_SSSE3

./scripts/config --module CONFIG_CRYPTO_AES
./scripts/config --module CONFIG_CRYPTO_XTS
./scripts/config --module CONFIG_CRYPTO_SHA256
./scripts/config --module CONFIG_CRYPTO_USER_API_SKCIPHER

# --- ACPI --------------------------------------------------------------------
./scripts/config --enable CONFIG_ACPI
./scripts/config --enable CONFIG_ACPI_AC
./scripts/config --enable CONFIG_ACPI_BATTERY
./scripts/config --enable CONFIG_ACPI_BUTTON

# --- PCIe (X670E: PCIe 5.0 host) ---------------------------------------------
./scripts/config --enable  CONFIG_PCIEAER
./scripts/config --enable  CONFIG_PCIEPORTBUS
./scripts/config --disable CONFIG_PCIEASPM

# --- Memory: 64 GB DDR5 -----------------------------------------------------
./scripts/config --enable  CONFIG_TRANSPARENT_HUGEPAGE
./scripts/config --disable CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS
./scripts/config --enable  CONFIG_TRANSPARENT_HUGEPAGE_MADVISE  # mutually exclusive with ALWAYS
./scripts/config --enable  CONFIG_COMPACTION
./scripts/config --enable  CONFIG_MIGRATION
./scripts/config --disable CONFIG_KSM                           # 64 GB = no need to deduplicate pages
./scripts/config --enable  CONFIG_NUMA_BALANCING
./scripts/config --enable  CONFIG_NUMA_BALANCING_DEFAULT_ENABLED
./scripts/config --enable  CONFIG_COMPACTION_FREQUENCY

# --- GPU: NVIDIA 3070 only – disable everything else ------------------------
./scripts/config --enable  CONFIG_DRM
./scripts/config --enable  CONFIG_DRM_NVIDIA
./scripts/config --enable  CONFIG_DRM_SIMPLEDRM                 # EFI boot frame buffer before NVIDIA inits
./scripts/config --enable  CONFIG_DRM_FBDEV_EMULATION

# Framebuffer
./scripts/config --enable  CONFIG_FB
./scripts/config --enable  CONFIG_FB_EFI
./scripts/config --enable  CONFIG_FB_VESA
./scripts/config --disable CONFIG_FB_NVIDIA                     # proprietary driver handles this

# AMD GPU drivers – not needed (disabled in BIOS)
./scripts/config --disable CONFIG_DRM_AMDGPU
./scripts/config --disable CONFIG_DRM_AMDGPU_CIK
./scripts/config --disable CONFIG_DRM_AMDGPU_SI
./scripts/config --disable CONFIG_DRM_RADEON

# Other unused GPU / accelerator drivers
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
./scripts/config --disable CONFIG_DRM_ACCEL_HABANALABS
./scripts/config --disable CONFIG_DRM_ACCEL_IVPU
./scripts/config --disable CONFIG_DRM_ACCEL_QAIC
./scripts/config --disable CONFIG_DRM_ACCEL_AMDXDNA

# --- Sound: onboard Realtek via HDA Intel – no HDMI audio -------------------
./scripts/config --module  CONFIG_SND_HDA_INTEL                 # Als Modul (wird nur bei Bedarf geladen)
./scripts/config --module  CONFIG_SND_HDA_CODEC_REALTEK         # Als Modul
./scripts/config --module  CONFIG_SND_HDA_CODEC_GENERIC         # Als Modul
./scripts/config --disable CONFIG_SND_HDA_CODEC_HDMI
./scripts/config --disable CONFIG_SND_HDA_INTEL_HDMI_SILENT_STREAM
./scripts/config --disable CONFIG_SOUND_HDA_CODEC_HDMI         # belt-and-suspenders

# PipeWire / PulseAudio basics
./scripts/config --module CONFIG_SND_TIMER
./scripts/config --module CONFIG_SND_PCM

# --- USB ---------------------------------------------------------------------
./scripts/config --enable CONFIG_USB_SUPPORT
./scripts/config --enable CONFIG_USB_STORAGE
./scripts/config --enable CONFIG_USB_XHCI_HCD
./scripts/config --disable CONFIG_USB_EHCI_HCD

# --- Input -------------------------------------------------------------------
./scripts/config --enable CONFIG_INPUT_EVDEV
./scripts/config --module CONFIG_HID_GENERIC
./scripts/config --module CONFIG_USB_HID

# No game controllers on this system
./scripts/config --disable CONFIG_INPUT_JOYDEV
./scripts/config --disable CONFIG_JOYSTICK_XPAD        # Xbox Controller
./scripts/config --disable CONFIG_HID_PLAYSTATION      # PS5 Controller
./scripts/config --disable CONFIG_HID_STEAM            # Steam Controller

# --- Network: Realtek 2.5GbE + Bluetooth – no WiFi --------------------------
./scripts/config --enable  CONFIG_INET
./scripts/config --enable  CONFIG_IPV6
./scripts/config --enable  CONFIG_NET_VENDOR_REALTEK
./scripts/config --enable  CONFIG_R8169          # ← Mainline Driver (RTL8125 ✓)
./scripts/config --enable  CONFIG_R8169_LEDS
./scripts/config --disable CONFIG_R8125          # ← Realtek OOT Driver

# Disable WiFi stack entirely
./scripts/config --disable CONFIG_WIRELESS
./scripts/config --disable CONFIG_WLAN
./scripts/config --disable CONFIG_CFG80211
./scripts/config --disable CONFIG_MAC80211
./scripts/config --disable CONFIG_IWLWIFI
./scripts/config --disable CONFIG_ATH9K
./scripts/config --disable CONFIG_ATH11K
./scripts/config --disable CONFIG_RT2X00
./scripts/config --disable CONFIG_MT76

# Bluetooth – benötigt auf diesem System
./scripts/config --module CONFIG_BT                             # Als Modul (wird nur bei Bedarf geladen)
./scripts/config --module CONFIG_BT_RFCOMM                      # Serial-Profil (z. B. Tastatur)
./scripts/config --module CONFIG_BT_HIDP                        # HID-Profil (Maus, Headset)
./scripts/config --module CONFIG_BT_BNEP                        # Network profile
./scripts/config --module CONFIG_BT_HCIBTUSB                    # USB Bluetooth adapter

# All other NIC vendors
for v in INTEL 3COM ADAPTEC ALACRITECH AGERE ALTEON AMAZON AMD AQUANTIA ARC ASIX ATHEROS \
         BROADCOM CADENCE CAVIUM CHELSIO CISCO CORTINA DEC DLINK EMULEX \
         EZCHIP GOOGLE HUAWEI MARVELL MELLANOX MICREL MICROCHIP MICROSEMI \
         MYRICOM NATSEMI NETERION NETRONOME NI NVIDIA OKI PACKET_ENGINES \
         QLOGIC QUALCOMM RDC ROCKER SAMSUNG SEEQ SILAN SIS SMSC STMICRO \
         SUN SYNOPSYS TEHUTI TI WANGXUN VIA WIZNET XILINX; do
    ./scripts/config --disable "CONFIG_NET_VENDOR_${v}"
done

# --- Network performance: BBR + FQ + Cake ------------------------------------
./scripts/config --enable  CONFIG_NET_SCH_FQ
./scripts/config --enable  CONFIG_NET_SCH_FQ_CODEL
./scripts/config --enable  CONFIG_NET_SCH_CAKE
./scripts/config --enable  CONFIG_TCP_CONG_BBR
./scripts/config --set-str CONFIG_DEFAULT_TCP_CONG "bbr"

# --- Storage: NVMe -----------------------------------------------------------
./scripts/config --enable  CONFIG_NVME_PCI
./scripts/config --enable  CONFIG_NVME_CORE
./scripts/config --enable  CONFIG_BLK_DEV_NVME
./scripts/config --enable  CONFIG_NVME_MULTIPATH
./scripts/config --enable  CONFIG_NVME_HWMON
./scripts/config --set-val CONFIG_BLK_DEV_NVME_NUM_QUEUES 16 # 16 for PCIe 5.0 x4 SSDs

# SATA für deine zusätzlichen SSDs/HDD
./scripts/config --enable CONFIG_SATA_AHCI
./scripts/config --enable CONFIG_ATA

# SCSI Layer (für SATA)
./scripts/config --enable CONFIG_SCSI
./scripts/config --enable CONFIG_BLK_DEV_SD

# --- I/O scheduler: BFQ (good for mixed read/write desktop workloads) -------
./scripts/config --enable  CONFIG_MQ_IOSCHED_DEADLINE
./scripts/config --enable  CONFIG_IOSCHED_BFQ
./scripts/config --enable  CONFIG_BFQ_GROUP_IOSCHED
./scripts/config --set-str CONFIG_DEFAULT_IOSCHED "bfq"

# --- Filesystems -------------------------------------------------------------
./scripts/config --enable  CONFIG_EXT4_FS
./scripts/config --enable  CONFIG_BTRFS_FS
./scripts/config --enable  CONFIG_VFAT_FS                       # ESP
./scripts/config --enable  CONFIG_NTFS3_FS                      # modern NTFS driver
./scripts/config --enable  CONFIG_FUSE_FS                       # AppImage etc.
./scripts/config --enable  CONFIG_OVERLAY_FS                    # Flatpak / Snap / containers
./scripts/config --enable  CONFIG_TMPFS
./scripts/config --enable  CONFIG_PROC_FS
./scripts/config --enable  CONFIG_SYSFS

# Exotic – not needed
./scripts/config --disable CONFIG_REISERFS_FS
./scripts/config --disable CONFIG_JFS_FS
# ./scripts/config --disable CONFIG_F2FS_FS
./scripts/config --disable CONFIG_NILFS2_FS
./scripts/config --disable CONFIG_EROFS_FS
./scripts/config --disable CONFIG_XFS_FS

# --- Containers / Flatpak / Snap (Mint) --------------------------------------
./scripts/config --enable CONFIG_USER_NS
./scripts/config --enable CONFIG_CGROUPS
./scripts/config --enable CONFIG_NAMESPACES

# --- Security: AppArmor (Mint default) – no SELinux -------------------------
./scripts/config --enable  CONFIG_SECURITY_APPARMOR
./scripts/config --enable  CONFIG_DEFAULT_SECURITY_APPARMOR
./scripts/config --disable CONFIG_SECURITY_SELINUX
# ../scripts/config --disable CONFIG_RETPOLINE
# ../scripts/config --disable CONFIG_CPU_SPEC_STORE_BYPASS_DISABLE
# ../scripts/config --disable CONFIG_PAGE_TABLE_ISOLATION
# ../scripts/config --disable CONFIG_SECURITY_SMACK
# ../scripts/config --disable CONFIG_IMA

# --- VFIO (GPU passthrough / isolation) --------------------------------------
./scripts/config --module CONFIG_VFIO                           # Als Modul (nur bei Bedarf für VMs)
./scripts/config --module CONFIG_VFIO_PCI                       # Als Modul

# --- Unused subsystems -------------------------------------------------------
./scripts/config --disable CONFIG_HAMRADIO
./scripts/config --disable CONFIG_CAN
./scripts/config --disable CONFIG_NFC
./scripts/config --disable CONFIG_WIMAX
./scripts/config --disable CONFIG_PCMCIA
./scripts/config --disable CONFIG_FIREWIRE
./scripts/config --disable CONFIG_INFINIBAND
./scripts/config --disable CONFIG_PHONE
./scripts/config --disable CONFIG_ARCNET
./scripts/config --disable CONFIG_ISDN
./scripts/config --disable CONFIG_PARPORT
./scripts/config --disable CONFIG_BLK_DEV_FD                    # floppy

# --- Unused network protocols ------------------------------------------------
./scripts/config --disable CONFIG_IPX
./scripts/config --disable CONFIG_ATALK
./scripts/config --disable CONFIG_X25
./scripts/config --disable CONFIG_DECNET

# --- Faster boot -------------------------------------------------------------
./scripts/config --disable CONFIG_PRINTK_TIME
./scripts/config --disable CONFIG_BOOT_PRINTK_DELAY

# --- Debug / tracing: all off for production ---------------------------------
./scripts/config --disable CONFIG_DEBUG_KERNEL
./scripts/config --disable CONFIG_DEBUG_INFO
./scripts/config --disable CONFIG_DEBUG_INFO_DWARF4
./scripts/config --disable CONFIG_DEBUG_INFO_DWARF5
./scripts/config --disable CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
./scripts/config --disable CONFIG_DEBUG_FS
./scripts/config --disable CONFIG_FTRACE
./scripts/config --disable CONFIG_KPROBES
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
./scripts/config --disable CONFIG_DRM_DEBUG_DP_MST_TOPOLOGY_REFS
./scripts/config --disable CONFIG_DRM_DEBUG_MODESET_LOCK
./scripts/config --disable CONFIG_DRM_PANIC_DEBUG

# --- Module signing: clear keys (custom build, not distro-signed) -----------
./scripts/config --set-str CONFIG_SYSTEM_REVOCATION_KEYS ""
./scripts/config --set-str CONFIG_SYSTEM_TRUSTED_KEYS ""
#../scripts/config --disable MODULE_SIG
#../scripts/config --disable CONFIG_MODULE_SIG_ALL
