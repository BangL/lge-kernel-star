#!/bin/bash

cd $PWD
buildtype=$1

# toolchain
EABI="${HOME}/android/kernel/toolchain/toolchain/bin"
export CCOMPILER=${EABI}/arm-eabi-

# config
config="star_cyanogenmod_defconfig"






#-----------------------------
# Do not edit below this
#-----------------------------

# check for valid toolchain
if [ ! -d "$EABI" ]; then
    echo "ERROR: $EABI is not a directory!"
    exit 1
fi

# function to set a new ramhack value
sethack() {
    hack="$1"
    awk '/^#define RAMHACK_SIZE/ {print "#define RAMHACK_SIZE '$hack'"; found=1} !/^#define RAMHACK_SIZE/ {print $0} END {if (!found) {print "#define RAMHACK_SIZE '$hack'" }}' include/linux/skynet.h > include/linux/skynet.h.tmp
    cp include/linux/skynet.h.tmp include/linux/skynet.h
    rm include/linux/skynet.h.tmp
}

compile_kernel() {
    cp arch/arm/configs/$config .config
    make ARCH=arm CROSS_COMPILE=$CCOMPILER oldconfig 
    make ARCH=arm CROSS_COMPILE=$CCOMPILER -j`grep 'processor' /proc/cpuinfo | wc -l`
    cp arch/arm/boot/zImage build/tmp/Skynet/zImage"$1"
}

# prepare modules directory
if [ ! -d build/tmp/Skynet/files/modules ]; then
    mkdir -p build/tmp/Skynet/files/modules
fi

# remove old modules
rm build/tmp/Skynet/files/modules/*

# remove old kernel builds
rm build/tmp/Skynet/zImage*

if [ "$buildtype" == "release" ]; then
    # build all versions
    hacks="0 32 48 64 80 96"
    for hack in $hacks
    do

        sethack "$hack"
        compile_kernel "$hack"

    done
    # set hack back to 64 to keep repo status
    sethack "64"
else
    # just testing, so just build 64mib version
    sethack "64"
    compile_kernel "64"
fi

# copy new modules, no matter which name they have or where they are
for i in `find . -path build -prune -o -name "*.ko" -print`
do
    cp $i build/tmp/Skynet/files/modules/
done

# pack the new build
echo "Packing new kernel ..."
now=`date +%Y%m%d%H%M`
rm build/*.zip
cd build || exit
zip -r Skynet64_$now-bravia-cam-log-uv.zip . > /dev/null
cd ..
echo "Done."

exit 0
