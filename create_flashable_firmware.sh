#!/bin/bash

if [ -z $1 ]; then
    echo "Usage: create_flashable_firmware.sh ROM_FILE"
    exit 1
fi

if [ ! -f $1 ]; then
    echo "** File not available."
    exit 1
fi

MIUI_ZIP_NAME=$(basename $1)
MIUI_ZIP_DIR=$(dirname $1)

if [ -z ${2+x} ]; then
    OUTPUT_DIR=$2
else
    OUTPUT_DIR=$MIUI_ZIP_DIR
fi

DATE=$(date "+%Y-%m-%d %H:%M:%S")
HOSTNAME=$(cat /etc/hostname)

function creatupscrpt() {
    cat > $2 << EOF
$(cat $1 | awk '/getprop/ && /ro.product.device/')
$(cat $1 | awk '/ui_print/ && /Target:/')
show_progress(0.200000, 10);

# Created by Xiaomi Flashable Firmware Creator
# $DATE - $HOSTNAME

ui_print("Patching firmware images...");
$(cat $1 | awk '/package_extract_file/ && /firmware-update\//')
show_progress(0.100000, 2);
set_progress(1.000000);
EOF

    if grep -wq "/firmware/image/sec.dat" "$2"
    then
        sed -i "s|/firmware/image/sec.dat|/dev/block/bootdevice/by-name/sec|g" "$2"
    elif grep -wq "/firmware/image/splash.img" "$2"
    then
        sed -i "s|/firmware/image/splash.img|/dev/block/bootdevice/by-name/splash|g" "$2"
    fi
}

mkdir /tmp/xiaomi-fw-zip-creator/

mkdir /tmp/xiaomi-fw-zip-creator/unzipped
unzip -q $MIUI_ZIP_DIR/$MIUI_ZIP_NAME -d /tmp/xiaomi-fw-zip-creator/unzipped/

if [ ! -f /tmp/xiaomi-fw-zip-creator/unzipped/META-INF/com/google/android/update-binary ] || [ ! -f /tmp/xiaomi-fw-zip-creator/unzipped/META-INF/com/google/android/updater-script ] || [ ! -d /tmp/xiaomi-fw-zip-creator/unzipped/firmware-update/ ]; then
    echo "** This zip doesn't contain firmware directory."
    rm -rf /tmp/xiaomi-fw-zip-creator/
    exit 1
fi

mkdir /tmp/xiaomi-fw-zip-creator/out/

mv /tmp/xiaomi-fw-zip-creator/unzipped/firmware-update/ /tmp/xiaomi-fw-zip-creator/out/

mkdir -p /tmp/xiaomi-fw-zip-creator/out/META-INF/com/google/android
mv /tmp/xiaomi-fw-zip-creator/unzipped/META-INF/com/google/android/update-binary /tmp/xiaomi-fw-zip-creator/out/META-INF/com/google/android/
creatupscrpt /tmp/xiaomi-fw-zip-creator/unzipped/META-INF/com/google/android/updater-script /tmp/xiaomi-fw-zip-creator/out/META-INF/com/google/android/updater-script

LASTLOC=$(pwd)
cd /tmp/xiaomi-fw-zip-creator/out/
zip -q -r9 /tmp/xiaomi-fw-zip-creator/out/fw_$MIUI_ZIP_NAME META-INF/ firmware-update/
cd $LASTLOC
mv /tmp/xiaomi-fw-zip-creator/out/fw_$MIUI_ZIP_NAME $OUTPUT_DIR/

rm -rf /tmp/xiaomi-fw-zip-creator/
