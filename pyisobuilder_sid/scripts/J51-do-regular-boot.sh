#!/bin/bash
echo "Run J51-do-regular-boot.sh"
ISO_BUILD_PATH=$1
ISO_FILE=$2

pushd ${ISO_BUILD_PATH}

[[ -f ${ISO_BUILD_PATH}/md5sum.txt ]] && sudo rm -f ${ISO_BUILD_PATH}/md5sum.txt 
find . -type f -print0  | xargs -0 sudo md5sum | grep -v isolinux/ > md5sum.txt 
sed -i '/md5sum.txt/d' md5sum.txt

#genisoimage -D -r -V "$DISTRO_NAME $VERSION (${ARCH})" -cache-inodes -J -l \
#    -b isolinux/isolinux.bin -c isolinux/boot.cat \
#    -no-emul-boot -boot-load-size 4 -boot-info-table \
#    -input-charset utf-8 \
#    -o ${ISO_FILE} . 
#isohybrid --partok ${ISO_FILE}
xorriso -as mkisofs -D -r -V "$DISTRO_NAME $VERSION (${ARCH})" -cache-inodes -J -l \
    -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -input-charset utf-8 \
    -o ${ISO_FILE} . 
if [ -x /usr/bin/isohybrid ];then
    isohybrid --partok ${ISO_FILE} 
else
    echo "[WARN] No isohybrid found, please install syslinux-utils."
fi
popd >/dev/null
