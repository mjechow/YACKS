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


sudo apt install \
  clang-19 \
  lld-19 \
  llvm-19 \
  llvm-19-dev \
  libclang-common-19-dev \
  libllvm19 \
  clang-tools-19 \
  libomp-19-dev \
  ccache \
  binutils \
  make \
  bc \
  bison \
  flex \
  libelf-dev \
  libssl-dev \
  libncurses-dev \
  python3 \
  pahole \
  dwarves \
  debhelper \
  rsync \
  cpio

❯ sudo update-alternatives --install /usr/bin/clang clang /usr/lib/llvm-19/bin/clang 100
sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/lib/llvm-19/bin/clang++ 100
sudo update-alternatives --install /usr/bin/ld.lld ld.lld /usr/lib/llvm-19/bin/ld.lld 100
sudo update-alternatives --install /usr/bin/llvm-ar llvm-ar /usr/lib/llvm-19/bin/llvm-ar 100
sudo update-alternatives --install /usr/bin/llvm-nm llvm-nm /usr/lib/llvm-19/bin/llvm-nm 100
sudo update-alternatives --install /usr/bin/llvm-objcopy llvm-objcopy /usr/lib/llvm-19/bin/llvm-objcopy 100
sudo update-alternatives --install /usr/bin/llvm-objdump llvm-objdump /usr/lib/llvm-19/bin/llvm-objdump 100
sudo update-alternatives --install /usr/bin/llvm-strip llvm-strip /usr/lib/llvm-19/bin/llvm-strip 100
sudo update-alternatives --install /usr/bin/llvm-ranlib llvm-ranlib /usr/lib/llvm-19/bin/llvm-ranlib 100
sudo update-alternatives --install /usr/bin/llvm-readelf llvm-readelf /usr/lib/llvm-19/bin/llvm-readelf 100
