YACKS
======

YACS is yet another compile kernel script. It is specifically developed for building a Ubuntu kernel and tested on Linux Mint.

It uses the Ubuntu mainline kernel config from https://kernel.ubuntu.com/~kernel-ppa/mainline/ found in the Linux modules generic dep package for configuration of the kernel.
Afterward it updates the kernel sources (linux-rolling-stable branch) from the official sources: https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/. 

It modifies the kernel config for O3 optimizations and disables all debugging before compiling the sources.

At last, it offers the installation of the new build kernel dep packages.

## Requirements

* installed git
* installed classic gcc tool chain 
* cloned git sources in a sub directory called "linux"

## Constraints

* It only compiles amd64 architecture source code.
* Atm the Linux source code has to be checked out and available in the directory "linux" next to the script

## Todo
