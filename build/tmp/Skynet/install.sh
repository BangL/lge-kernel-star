#!/sbin/sh

###########################################################
# Methods
###########################################################

ui_print() {
    echo ui_print "$@" 1>&$UPDATE_CMD_PIPE;
    if [ -n "$@" ]; then
        echo ui_print 1>&$UPDATE_CMD_PIPE;
    fi
}

fatal() {
    ui_print "$@";
    exit 1;
}

###########################################################
# Constants
###########################################################

updatename=`echo $UPDATE_FILE | awk '{ sub(/^.*\//,"",$0); sub(/.zip$/,"",$0); print }'`
kernelver=`echo $updatename | awk 'BEGIN {RS="-"; ORS="-"}; NR<=1 {print; ORS=""}'`
variant=`echo $updatename | awk 'BEGIN {RS="_"}; NR<=1 {print; ORS=""}'`
args=`echo $updatename | awk 'BEGIN {RS="-"}; NR>1 {print}'`
hack=`echo $variant | sed 's/Skynet//g'`

basedir=`dirname $0`
BB=$basedir/busybox
chmod="$BB chmod"
gunzip="$BB gunzip"
cpio="$BB cpio"
find="$BB find"
gzip="$BB gzip"
warning=0

###########################################################
# Welcome message
###########################################################

ui_print ""
ui_print " **********************************"
ui_print " **  Skynet kernel for CM7/MIUI  **"
ui_print " **       by MisjudgedTwat       **"
ui_print " ** based on ironkrnL & temaseks **"
ui_print " **********************************"
ui_print ""

###########################################################
# Compatibility check
###########################################################
ui_print "-- Compatibility check --"

cymo=`cat /system/build.prop | awk 'tolower($0) ~ /cyanogenmod/ { printf "1"; exit 0 }'`
gb=`cat /system/build.prop | awk '/version.release=2.3/ { printf "1"; exit 0 }'`
cwm=`cat /tmp/recovery.log | awk 'tolower($0) ~ /v5.0./ { printf "1"; exit 0 }'`
if [ "$cwm" == "1" ]; then
    ui_print "Installing from CWM v5.0.2.x"
else
    ui_print "Installing from unsupported CWM"
fi
if [ "$gb" != "1" ]; then
    fatal "Current ROM not compatible! Aborting."
fi
if [ "$cymo" != "1" ]; then
    fatal "Current ROM not compatible! Aborting."
fi
hacks="0 32 48 64 80 96"
okhack=`echo $hacks | awk '/'$hack'/ { printf "1"; exit 0 }'`
if [ "$okhack" == "1" ]; then
    ui_print "Installing $hack MiB hack variant"
else
    fatal "$hack MiB ramhack not available on $android! Aborting."
fi

ui_print "OK"
ui_print ""

###########################################################
# Flag parsing
###########################################################
ui_print "-- Flag parsing --"

flags=
parse_flag() {
    fvalue=`echo $args | awk '/'$curflag'/ { printf "1"; exit 0 }'`
    if [ "$fvalue" == "1" ]; then
        args=`echo $args | sed 's/'$curflag'//g'`
        flags="$flags $curflag"
    fi
}

curflag=anim; parse_flag; anim=$fvalue          # disable installation of bangmod bootanimation
curflag=basic; parse_flag; basic=$fvalue        # disable even the most basic tweaks
curflag=bravia; parse_flag; bravia=$fvalue      # enable installation of sony bravia engine
curflag=cam; parse_flag; cam=$fvalue            # enable installation of modded stock cam by kostja
curflag=cron; parse_flag; cron=$fvalue          # disable installation of cron job for automatic cache dropping
curflag=font; parse_flag; font=$fvalue          # disable installation of roboto font
curflag=fsync; parse_flag; fsync=$fvalue        # disable fsync
curflag=gapps; parse_flag; gapps=$fvalue        # disable installation of google apps
curflag=jrnl; parse_flag; jrnl=$fvalue          # enable ext4 journal removal and 'risky' mount options (not recommended)
curflag=keep; parse_flag; keep=$fvalue          # disable deletion of unnecessary CM apps
curflag=ksm; parse_flag; ksm=$fvalue            # disable activation of kernel samepage merging
curflag=log; parse_flag; log=$fvalue            # enable log removal on boot
curflag=nitz; parse_flag; nitz=$fvalue          # install nitz fix for su660 basebands (will get removed if not set)
curflag=prop; parse_flag; prop=$fvalue          # disable tweaking of build.prop
curflag=sql; parse_flag; sql=$fvalue            # disable installation of tweaked sqlite.so
curflag=uv; parse_flag; uv=$fvalue              # enable slight undervolt

if [ "$args" != "" ]; then
    ui_print "WARNING: unrecognised flags: $args"
    warning=$((warning + 1))
fi
if [ -n "$flags" ]; then
    ui_print "active flags: $flags"
else
    ui_print "No flags selected."
fi

ui_print "OK"
ui_print ""

###########################################################
# Kernel installation
###########################################################
ui_print "-- Kernel installation --"

ui_print "Dumping previous boot image to $basedir/boot.old ..."
cd $basedir
$BB dd if=/dev/block/mmcblk0p5 of=$basedir/boot.old
if [ ! -f $basedir/boot.old ]; then
    fatal "ERROR: Dumping old boot image failed"
fi

ui_print "Extracting ramdisk from old boot image ..."
ramdisk="$basedir/boot.old-ramdisk.gz"
$basedir/unpackbootimg -i $basedir/boot.old -o $basedir/ -p 0x800
if [ "$?" -ne 0 -o ! -f $ramdisk ]; then
    fatal "ERROR: Unpacking old boot image failed"
fi

ui_print "Unpacking ramdisk ..."
mkdir $basedir/ramdisk
cd $basedir/ramdisk
$gunzip -c $basedir/boot.old-ramdisk.gz | $cpio -i
if [ ! -f init.rc ]; then
    fatal "ERROR: Unpacking ramdisk failed!"
elif [ ! -f init.p990.rc ]; then
    fatal "ERROR: Invalid ramdisk! Is this a p990?"
fi

ui_print "Building new ramdisk ..."
$BB find . | $BB cpio -o -H newc | $BB gzip > $basedir/boot.img-ramdisk.gz
if [ "$?" -ne 0 -o ! -f $basedir/boot.img-ramdisk.gz ]; then
    fatal "ERROR: Ramdisk building failed!"
fi

ui_print "Packing new boot image ..."
cd $basedir
$basedir/mkbootimg --kernel $basedir/zImage"$hack" --ramdisk $basedir/boot.img-ramdisk.gz --cmdline "mem=$((512-(128-$hack)-1))M@0M nvmem=$((128-$hack))M@$((512-(128-$hack)))M loglevel=0 muic_state=1 lpj=9994240 CRC=3010002a8e458d7 vmalloc=256M brdrev=1.0 video=tegrafb console=ttyS0,115200n8 usbcore.old_scheme_first=1 tegraboot=sdmmc tegrapart=recovery:35e00:2800:800,linux:34700:1000:800,mbr:400:200:800,system:600:2bc00:800,cache:2c200:8000:800,misc:34200:400:800,userdata:38700:c0000:800 androidboot.hardware=p990" -o $basedir/boot.img --base 0x10000000
if [ "$?" -ne 0 -o ! -f boot.img ]; then
    fatal "ERROR: Packing boot image failed!"
fi

ui_print "Flashing the new boot image ..."
$BB dd if=/dev/zero of=/dev/block/mmcblk0p5
$BB dd if=$basedir/boot.img of=/dev/block/mmcblk0p5
if [ "$?" -ne 0 ]; then
    fatal "ERROR: Flashing boot image failed!"
fi

ui_print "Deleting old kernel modules ..."
rm -rf /system/lib/modules
mkdir /system/lib/modules

ui_print "Installing new kernel modules ..."
cp -r $basedir/files/modules/* /system/lib/modules
if [ "$?" -ne 0 -o ! -d /system/lib/modules ]; then
    ui_print "WARNING: kernel modules not installed!"
    warning=$((warning + 1))
fi

ui_print "OK"
ui_print ""

###########################################################
# Tweaks
###########################################################
ui_print "-- Tweaks --"

if [ "$basic" != "1" ]; then
    ui_print "Cleaning up init.d scripts ..."
    cp /system/etc/init.d/01sysctl $basedir/files/
    cp /system/etc/init.d/03firstboot $basedir/files/
    cp /system/etc/init.d/04modules $basedir/files/
    cp /system/etc/init.d/05mountsd $basedir/files/
    cp /system/etc/init.d/06mountdl $basedir/files/
    cp /system/etc/init.d/20userinit $basedir/files/
    rm -rf /system/etc/init.d
    mkdir /system/etc/init.d
    cp $basedir/files/01sysctl /system/etc/init.d/01sysctl
    cp $basedir/files/03firstboot /system/etc/init.d/03firstboot
    cp $basedir/files/04modules /system/etc/init.d/04modules
    cp $basedir/files/05mountsd /system/etc/init.d/05mountsd
    cp $basedir/files/06mountdl /system/etc/init.d/06mountdl
    cp $basedir/files/20userinit /system/etc/init.d/20userinit
    chmod 775 /system/etc/init.d/01sysctl
    chmod 775 /system/etc/init.d/03firstboot
    chmod 775 /system/etc/init.d/04modules
    chmod 775 /system/etc/init.d/05mountsd
    chmod 775 /system/etc/init.d/06mountdl
    chmod 775 /system/etc/init.d/20userinit

    ui_print "Installing new init.d scripts ..."
    touch /system/etc/.root_browser
    cp $basedir/files/90mmcblk0 /system/etc/init.d/90mmcblk0
    cp $basedir/files/91mmcblk1 /system/etc/init.d/91mmcblk1
    cp $basedir/files/94oom /system/etc/init.d/94oom
    cp $basedir/files/98vm /system/etc/init.d/98vm
    chmod 775 /system/etc/init.d/90mmcblk0
    chmod 775 /system/etc/init.d/91mmcblk1
    chmod 775 /system/etc/init.d/94oom
    chmod 775 /system/etc/init.d/98vm
    
    chmod 777 /system/bin/compcache
    cp $basedir/files/compcache /system/bin/compcache
    chmod 775 /system/bin/compcache
fi

if [ "$cron" != "1" ]; then
    ui_print "Installing cron job for automatic cache dropping ..."
    mkdir -p /data/cron/crontabs
    cp $basedir/files/root /data/cron/crontabs/root
    cp $basedir/files/92cron /system/etc/init.d/92cron
    chmod 775 /system/etc/init.d/92cron
    chmod 775 /data/cron/crontabs/root
    touch /data/group
    touch /data/shadow
    touch /data/passwd
    ln -s /data/passwd /system/etc/passwd
    ln -s /data/group /system/etc/group
    ln -s /data/shadow /system/etc/shadow
fi

if [ "$jrnl" == "1" ]; then
    ui_print "Disabling ext4 journaling ..."
    cp $basedir/files/80mountopt /system/etc/init.d/80mountopt
    cp $basedir/files/81nojournal /system/etc/init.d/81nojournal
    chmod 775 /system/etc/init.d/80mountopt
    chmod 775 /system/etc/init.d/81nojournal
fi

if [ "$log" == "1" ]; then
    ui_print "Enabling syslog deletion on boot ..."
    cp $basedir/files/02rmlog /system/etc/init.d/02rmlog
    chmod 775 /system/etc/init.d/02rmlog
fi

if [ "$fsync" == "1" ]; then
    ui_print "Disabling fsync ..."
    cp $basedir/files/99fsync /system/etc/init.d/99fsync
    chmod 775 /system/etc/init.d/99fsync
fi

if [ "$ksm" != "1" ]; then
    ui_print "Enabling kernel samepage merging ..."
    cp $basedir/files/00banner.ksm /system/etc/init.d/00banner
    chmod 775 /system/etc/init.d/00banner
else
    cp $basedir/files/00banner /system/etc/init.d/00banner
    chmod 775 /system/etc/init.d/00banner
fi

if [ "$sql" != "1" ]; then
    ui_print "Installing libsqlite tweak ..."
    cp $basedir/files/libsqlite.so /system/lib/libsqlite.so
fi

if [ "$font" != "1" ]; then
    ui_print "Installing roboto fonts ..."
    cp $basedir/files/Clockopia.ttf /system/fonts/Clockopia.ttf
    cp $basedir/files/DroidSans-Bold.ttf /system/fonts/DroidSans-Bold.ttf
    cp $basedir/files/DroidSans.ttf /system/fonts/DroidSans.ttf
fi

if [ "$anim" != "1" ]; then
    ui_print "Installing BangMod bootanimation ..."
    rm /data/local/bootanimation.zip
    rm /system/media/bootanimation.zip
    cp $basedir/files/bootanimation.zip /system/media/bootanimation.zip
    chmod 775 /system/media/bootanimation.zip
fi

if [ "$cam" == "1" ]; then
    ui_print "Installing stock cam mod by Kostja ..."
    rm /system/media/audio/ui/camera_click.ogg
    rm /system/media/audio/ui/VideoRecord.ogg
    cp $basedir/files/Camera.apk /system/app/Camera.apk
    cp $basedir/files/libamce.so /system/lib/libamce.so
    cp $basedir/files/libcamera.so /system/lib/libcamera.so
fi

if [ "$bravia" == "1" ]; then
    ui_print "Installing Sony bravia engine ..."

    cp /system/build.prop /sdcard/build.prop.bak
    awk '/^ro.service.swiqi.supported/ {print "ro.service.swiqi.supported=true"; found=1} !/^ro.service.swiqi.supported/ {print $0} END {if (!found) {print "ro.service.swiqi.supported=true" }}' /sdcard/build.prop.bak > $basedir/build.prop.tmp1
    awk '/^persist.service.swiqi.enable/ {print "persist.service.swiqi.enable=1"; found=1} !/^persist.service.swiqi.enable/ {print $0} END {if (!found) {print "persist.service.swiqi.enable=1" }}' $basedir/build.prop.tmp1 > $basedir/build.prop.bravia
    if [ -s $basedir/build.prop.bravia ]; then
        cp $basedir/build.prop.bravia /system/build.prop
        cp -r $basedir/files/bravia/* /system
        chmod 777 /system/etc/be_movie
        chmod 777 /system/etc/be_photo
        chmod 777 /system/etc/permissions/com.sonyericsson.android.SwIqiBmp.xml
        chmod 777 /system/framework/com.sonyericsson.android.SwIqiBmp.jar
        chmod 777 /system/lib/libswiqibmpcnv.so
    else
        ui_print "WARNING: Installing Sony bravia engine failed!"
        warning=$((warning + 1))
    fi
fi

if [ "$gapps" != "1" ]; then
    ui_print "Installing Google apps ..."
    rm -f /system/app/CarHomeLauncher.apk
    rm -f /system/app/GenieWidget.apk
    rm -f /system/app/GoogleBackupTransport.apk
    rm -f /system/app/GoogleCalendarSyncAdapter.apk
    rm -f /system/app/GoogleContactsSyncAdapter.apk
    rm -f /system/app/GoogleFeedback.apk
    rm -f /system/app/GooglePartnerSetup.apk
    rm -f /system/app/GoogleQuickSearchBox.apk
    rm -f /system/app/QuickSearchBox.apk
    rm -f /system/app/GoogleServicesFramework.apk
    rm -f /system/app/LatinImeTutorial.apk
    rm -f /system/app/MarketUpdater.apk
    rm -f /system/app/MediaUploader.apk
    rm -f /system/app/NetworkLocation.apk
    rm -f /system/app/OneTimeInitializer.apk
    rm -f /system/app/SetupWizard.apk
    rm -f /system/app/Talk.apk
    rm -f /system/app/Vending.apk
    rm -f /system/app/YouTube.apk
    rm -f /system/etc/permissions/com.google.android.maps.xml
    rm -f /system/etc/permissions/features.xml
    rm -f /system/framework/com.google.android.maps.jar
    rm -f /system/lib/libtalk_jni.so
    rm -f /system/lib/libvoicesearch.so
    cp -r $basedir/files/gapps/* /system
fi

if [ "$keep" != "1" ]; then
    ui_print "Deleting CM Stats app ..."
    rm -f /system/app/CMStats.apk

    ui_print "Deleting CM update notification app ..."
    rm -f /system/app/CMUpdateNotify.apk

    ui_print "Deleting CM Live Wallpapers ..."
    rm -f /system/app/LiveWallapapers.apk
    rm -f /system/app/LiveWallapapersPicker.apk
    rm -f /system/app/LiveWallapapersPicker.apk
    rm -f /system/app/MagicSmokeWallpapers.apk
    rm -f /system/app/VisualizationWallpapers.apk

    ui_print "Deleting CM Protips ..."
    rm -f /system/app/Protips.apk
fi

if [ "$uv" == "1" ]; then
    ui_print "Enabling slight undervolt ..."
    additions="$additions uv"
    cp $basedir/files/93uv /system/etc/init.d/93uv
    chmod 775 /system/etc/init.d/93uv
fi

if [ "$prop" != "1" ]; then
    ui_print "Applying build.prop tweaks ..."
    if [ "$bravia" != "1" ]; then
        cp /system/build.prop /sdcard/build.prop.bak
        cp /sdcard/build.prop.bak /sdcard/build.prop.mod
    else
        cp $basedir/build.prop.bravia $basedir/build.prop.mod
    fi
    awk '/^wifi.supplicant_scan_interval/ {print "wifi.supplicant_scan_interval=320"; found=1} !/^wifi.supplicant_scan_interval/ {print $0} END {if (!found) {print "wifi.supplicant_scan_interval=320" }}' $basedir/build.prop.mod > $basedir/build.prop.mod0
    awk '/^windowsmgr.max_events_per_sec/ {print "windowsmgr.max_events_per_sec=60"; found=1} !/^windowsmgr.max_events_per_sec/ {print $0} END {if (!found) {print "windowsmgr.max_events_per_sec=60" }}' $basedir/build.prop.mod0 > $basedir/build.prop.mod1
    awk '/^ro.telephony.call_ring.delay/ {print "ro.telephony.call_ring.delay=400"; found=1} !/^ro.telephony.call_ring.delay/ {print $0} END {if (!found) {print "ro.telephony.call_ring.delay=400" }}' $basedir/build.prop.mod1 > $basedir/build.prop.mod2
    awk '/^dalvik.vm.heapsize/ {print "dalvik.vm.heapsize=32m"; found=1} !/^dalvik.vm.heapsize/ {print $0} END {if (!found) {print "dalvik.vm.heapsize=32m" }}' $basedir/build.prop.mod2 > $basedir/build.prop.mod3
    awk '/^ro.lg.proximity.delay/ {print "ro.lg.proximity.delay=25"; found=1} !/^ro.lg.proximity.delay/ {print $0} END {if (!found) {print "ro.lg.proximity.delay=25" }}' $basedir/build.prop.mod3 > $basedir/build.prop.mod4
    awk '/^ro.wifi.channels/ {print "ro.wifi.channels=14"; found=1} !/^ro.wifi.channels/ {print $0} END {if (!found) {print "ro.wifi.channels=14" }}' $basedir/build.prop.mod4 > $basedir/build.prop.mod5
    awk '/^debug.sf.hw/ {print "debug.sf.hw=1"; found=1} !/^debug.sf.hw/ {print $0} END {if (!found) {print "debug.sf.hw=1" }}' $basedir/build.prop.mod5 > $basedir/build.prop.mod6
    awk '/^debug.performance.tuning/ {print "debug.performance.tuning=1"; found=1} !/^debug.performance.tuning/ {print $0} END {if (!found) {print "debug.performance.tuning=1" }}' $basedir/build.prop.mod6 > $basedir/build.prop.mod7
    awk '/^video.accelerate.hw/ {print "video.accelerate.hw=1"; found=1} !/^video.accelerate.hw/ {print $0} END {if (!found) {print "video.accelerate.hw=1" }}' $basedir/build.prop.mod7 > $basedir/build.prop.mod8
    awk '/^persist.adb.notify/ {print "persist.adb.notify=0"; found=1} !/^persist.adb.notify/ {print $0} END {if (!found) {print "persist.adb.notify=0" }}' $basedir/build.prop.mod8 > $basedir/build.prop.mod9
    awk '/^net.tcp.buffersize.default/ {print "net.tcp.buffersize.default=4096,87380,256960,4096,16384,256960"; found=1} !/^net.tcp.buffersize.default/ {print $0} END {if (!found) {print "net.tcp.buffersize.default=4096,87380,256960,4096,16384,256960" }}' $basedir/build.prop.mod9 > $basedir/build.prop.mod10
    awk '/^net.tcp.buffersize.wifi/ {print "net.tcp.buffersize.wifi=4096,87380,256960,4096,16384,256960"; found=1} !/^net.tcp.buffersize.wifi/ {print $0} END {if (!found) {print "net.tcp.buffersize.wifi=4096,87380,256960,4096,16384,256960" }}' $basedir/build.prop.mod10 > $basedir/build.prop.mod11
    awk '/^net.tcp.buffersize.umts/ {print "net.tcp.buffersize.umts=4096,87380,256960,4096,16384,256960"; found=1} !/^net.tcp.buffersize.umts/ {print $0} END {if (!found) {print "net.tcp.buffersize.umts=4096,87380,256960,4096,16384,256960" }}' $basedir/build.prop.mod11 > $basedir/build.prop.mod12
    awk '/^net.tcp.buffersize.gprs/ {print "net.tcp.buffersize.gprs=4096,87380,256960,4096,16384,256960"; found=1} !/^net.tcp.buffersize.gprs/ {print $0} END {if (!found) {print "net.tcp.buffersize.gprs=4096,87380,256960,4096,16384,256960" }}' $basedir/build.prop.mod12 > $basedir/build.prop.mod13
    awk '/^net.tcp.buffersize.edge/ {print "net.tcp.buffersize.edge=4096,87380,256960,4096,16384,256960"; found=1} !/^net.tcp.buffersize.edge/ {print $0} END {if (!found) {print "net.tcp.buffersize.edge=4096,87380,256960,4096,16384,256960" }}' $basedir/build.prop.mod13 > $basedir/build.prop.mod14
    awk '/^dalvik.vm.heapstartsize/ {print "dalvik.vm.heapstartsize=5m"; found=1} !/^dalvik.vm.heapstartsize/ {print $0} END {if (!found) {print "dalvik.vm.heapstartsize=5m" }}' $basedir/build.prop.mod14 > $basedir/build.prop.mod15
    awk '/^dalvik.vm.heapgrowthlimit/ {print "dalvik.vm.heapgrowthlimit=32m"; found=1} !/^dalvik.vm.heapgrowthlimit/ {print $0} END {if (!found) {print "dalvik.vm.heapgrowthlimit=32m" }}' $basedir/build.prop.mod15 > $basedir/build.prop.mod16
    awk '/^ro.HOME_APP_ADJ/ {print "ro.HOME_APP_ADJ=1"; found=1} !/^ro.HOME_APP_ADJ/ {print $0} END {if (!found) {print "ro.HOME_APP_ADJ=1" }}' $basedir/build.prop.mod16 > $basedir/build.prop.mod17
    awk '/^ro.ril.disable.power.collapse/ {print "ro.ril.disable.power.collapse=0"; found=1} !/^ro.ril.disable.power.collapse/ {print $0} END {if (!found) {print "ro.ril.disable.power.collapse=0" }}' $basedir/build.prop.mod17 > $basedir/build.prop.mod18
    awk '/^pm.sleep_mode/ {print "pm.sleep_mode=1"; found=1} !/^pm.sleep_mode/ {print $0} END {if (!found) {print "pm.sleep_mode=1" }}' $basedir/build.prop.mod18 > $basedir/build.prop.mod19
    awk '/^ro.setupwizard.mode/ {print "ro.setupwizard.mode=DISABLED"; found=1} !/^ro.setupwizard.mode/ {print $0} END {if (!found) {print "ro.setupwizard.mode=DISABLED" }}' $basedir/build.prop.mod19 > $basedir/build.prop.modxx
    if [ -s $basedir/build.prop.modxx ]; then
        cp $basedir/build.prop.modxx /system/build.prop
    else
        ui_print "WARNING: Tweaking build.prop failed!"
        warning=$((warning + 1))
    fi
fi

if [ "$nitz" == "1" ]; then
    ui_print "Applying nitz fix ..."
    touch /data/local.prop
    awk '/^ro.telephony.nitz/ {print "ro.telephony.nitz=GMT"; found=1} !/^ro.telephony.nitz/ {print $0} END {if (!found) {print "ro.telephony.nitz=GMT" }}' /data/local.prop > $basedir/local.prop
    cp $basedir/local.prop /data/local.prop
else
    ui_print "Removing nitz fix ..."
    sed -i '/ro.telephony.nitz/d' /data/local.prop
fi

ui_print "OK"
ui_print ""

ui_print "Unmounting partitions..."
umount /system
umount /data
umount /cache

ui_print ""
if [ $warning -gt 0 ]; then
    ui_print "Skynet kernel installed with $warning warnings."
else
    ui_print "Skynet kernel installed. Enjoy!"
fi