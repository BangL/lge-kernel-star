#!/bin/bash




# compiler
EABI="${HOME}/android/system/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin"

# config
config="star_cyanogenmod_defconfig"






#-----------------------------
# Do not edit below this
#-----------------------------

basedir="$PWD"
ANYK="$basedir/build"
TARG="$ANYK/release.zip"

# define the compiler to use
export CCOMPILER=${EABI}/arm-eabi-
cd $basedir || exit

# prepare config from default
cp arch/arm/configs/$config .config
make ARCH=arm CROSS_COMPILE=$CCOMPILER oldconfig 

# make build using all cpu cores
make ARCH=arm CROSS_COMPILE=$CCOMPILER -j`grep 'processor' /proc/cpuinfo | wc -l`

# remove old modules
rm $ANYK/system/lib/modules/*

# remove old kernel build
rm $ANYK/kernel/zImage

# copy new kernel
cp arch/arm/boot/zImage $ANYK/kernel/

# copy new modules, no matter which name they have or where they are
for i in `find $basedir -path "$ANYK" -prune -o -name "*.ko" -print`
do
    cp $i $ANYK/system/lib/modules/
done

# pack the new build
cd $ANYK || exit
rm $TARG
zip -r $TARG .

exit 0
