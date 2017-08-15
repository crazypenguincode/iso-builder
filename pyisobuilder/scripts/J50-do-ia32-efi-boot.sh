#!/bin/bash
echo "RUN J50-do-ia32-efi-boot.sh"
set -e
CONF_PATH=$1
ISO_BUILD_PATH=$2
ISO_FILE=$3
LABEL=$4
LIVE_BOOT_PATH=$5


sudo mkdir -p ${ISO_BUILD_PATH}/{boot,EFI}
sudo cp -r ${CONF_PATH}/iso/ia32/{boot,EFI} ${ISO_BUILD_PATH}/

sudo cp ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/vmlinuz ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/vmlinuz.efi
[[ -f ${ISO_BUILD_PATH}/md5sum.txt ]] && sudo rm -f ${ISO_BUILD_PATH}/md5sum.txt 

pushd ${ISO_BUILD_PATH} 
find . -type f -print0  | xargs -0 sudo md5sum | grep -v isolinux/ > md5sum.txt 
sed -i '/md5sum.txt/d' md5sum.txt

xorriso -as mkisofs -o ${ISO_FILE} -no-pad \
    -isohybrid-mbr /usr/lib/syslinux/isohdpfx.bin \
    -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
    -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
    -appid "Linuxdeepin LiveCD" -publisher "LinuxDeepin Project <http://www.linuxdeepin.com>" \
    -V "$LABEL"  . 

popd >/dev/null
