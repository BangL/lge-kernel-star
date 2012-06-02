#!/bin/bash

# toolchain
EABI="${HOME}/android/kernel/toolchain/toolchain/bin"
export CCOMPILER=${EABI}/arm-eabi-

# config
config="star_cyanogenmod_defconfig"






#-----------------------------
# Do not edit below this
#-----------------------------

cd $PWD

# check for valid toolchain
if [ ! -d "$EABI" ]; then
    echo "ERROR: $EABI is not a directory!"
    exit 1
fi

# prepare modules directory
if [ ! -d build/tmp/Skynet/files/modules ]; then
    mkdir -p build/tmp/Skynet/files/modules
fi

# cleanup
rm build/tmp/Skynet/files/modules/*
rm build/tmp/Skynet/zImage
rm arch/arm/boot/zImage

# prepare config
cp arch/arm/configs/$config .config
make ARCH=arm CROSS_COMPILE=$CCOMPILER oldconfig

# build new kernel
echo "Building new kernel ..."
make ARCH=arm CROSS_COMPILE=$CCOMPILER -j`grep 'processor' /proc/cpuinfo | wc -l` > compile.log 2>&1

if [ ! -e arch/arm/boot/zImage ]; then
    echo "Build failed:"
    tail -n 50 compile.log
    echo "Read the full compile.log file if this excerpt doesn't give enough information."
    exit 1
fi

echo "Done."

# copy new kernel
cp arch/arm/boot/zImage build/tmp/Skynet/zImage

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
