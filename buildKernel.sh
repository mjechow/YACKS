#!/usr/bin/env bash

#set -x

kernelSrcDir=linux

cd "$kernelSrcDir" || exit 1
printf "Cleanup and checkout...\n"
if ! make distclean; then
  printf "Did you clone kernel sources to directory: %s?\n" "$kernelSrcDir"
  exit 1
else
  git reset --hard
  git clean -d -f
  git pull origin linux-rolling-lts || exit 1
  #git pull origin linux-rolling-stable || exit 1
fi

kernelVersionDir=$(git describe --tags --abbrev=0)
kernelVersion=${kernelVersionDir#v} # remove character "v"

kernelUrl=https://kernel.ubuntu.com/~kernel-ppa/mainline/${kernelVersionDir}
kernelVersionLong=$(echo "$kernelVersion" | awk 'BEGIN {FS="."}{printf "%02d%02d%02d", $1, $2, $3;}')
kernelFileName=$(curl -sL "$kernelUrl" | grep -iEo "linux-modules-${kernelVersion}-${kernelVersionLong}-generic_${kernelVersion}-${kernelVersionLong}.[0-9]{12}_amd64.deb" | head -1)
kernelDeb=${kernelUrl}/amd64/${kernelFileName}
if [[ ! -f "../${kernelFileName}" ]]; then
  printf "Downloading kernel %s sources from Ubuntu... " "$kernelVersion"
  if ! wget -O "../${kernelFileName}" -q "${kernelDeb}"; then
    printf "\nProblem downloading kernel %s sources from Ubuntu mainline: %s. Exiting now!\n" "$kernelVersion" "$kernelDeb"
    exit 1
  fi
  printf "success\n\n"  
fi

printf "Extracting config... "
dpkg-deb --fsys-tarfile "../${kernelFileName}" | tar xOf - ./boot/config-"${kernelVersion}"-"${kernelVersionLong}"-generic >.config || exit 1
cp .config ../config-"${kernelVersion}" || exit 1
printf "success\n\n"

git log -1 --pretty=oneline
echo "Do you wish to compile this kernel?"
echo "$ARCH"
select yn in "Yes" "No"; do
  case $yn in
    Yes) break ;;
    No) exit 1 ;;
  esac
done

export KCFLAGS="-march=native -mtune=native -O3 -pipe" KCPPFLAGS="-march=native -mtune=native -O3 -pipe"

printf "Modify kernel options...\n"
scripts/config --enable DEBUG_INFO_NONE
scripts/config --disable CONFIG_DEBUG_INFO
scripts/config --disable CONFIG_DEBUG_INFO_DWARF5
scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
scripts/config --disable DEBUG_INFO_DWARF4
scripts/config --disable DEBUG_INFO_DWARF5
scripts/config --disable CONFIG_MODULE_SIG_ALL
scripts/config --set-str SYSTEM_TRUSTED_KEYS ""
scripts/config --set-str SYSTEM_REVOCATION_KEYS ""


printf "Modify optimizations in Makefile...\n\n"
sed -i 's/-O2/-O3/g' Makefile

printf "make clean build...\n"
make clean
make ARCH=x86_64 oldconfig
time nice make -j$(($(nproc) + 1)) bindeb-pkg LOCALVERSION=-"$(whoami)"-"$(hostname)" >>../build.log || exit 1

cd .. || exit 1
printf "done!\nYou can install now using:\nsudo dpkg -i linux-*%s*.deb\n" "$(whoami)"

