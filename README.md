# YACKS

YACKS is yet another compile kernel script. It is specifically developed for
building a linux kernel and tested on Linux Mint.

It uses the Ubuntu mainline kernel config from <https://kernel.ubuntu.com/~kernel-ppa/mainline/>
found in the Linux modules generic dep package for configuration of the kernel.

It modifies the kernel config for optimizations and disables all debugging before compiling the sources.
Afterward it compiles the kernel.

At last, it offers the installation of the new build kernel dep packages.

## Requirements

- installed git
- installed classic gcc tool chain
- cloned git sources in a sub directory called "linux"

## Constraints

- It only compiles amd64 architecture source code.
- Atm the Linux source code has to be checked out and available in the
  directory "linux" next to the script

## Todo

- what is it
- who is it for
- how do i use it
- <https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/>

sudo apt install -y build-essential gcc make binutils \
  gcc-13 g++-13 libc6-dev libncurses-dev bison flex \
  libssl-dev libelf-dev bc pahole cpio

### new release should do 
Combined with scripts/kconfig/merge_config.sh, to handle dependency resolution properly. One fragment per concern — fragment-amd.config,
fragment-nvidia.config, fragment-security.config — composable and readable

