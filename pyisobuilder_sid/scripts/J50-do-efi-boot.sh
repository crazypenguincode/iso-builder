#!/bin/bash
set -e
CONF_PATH=$1
ISO_BUILD_PATH=$2
ISO_FILE=$3
LABEL=$4
LIVE_BOOT_PATH=$5


sudo cp -r ${CONF_PATH}/iso/{boot,EFI}/ ${ISO_BUILD_PATH}/
sudo cp ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/vmlinuz ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/vmlinuz.efi
[[ -f ${ISO_BUILD_PATH}/md5sum.txt ]] && sudo rm -f ${ISO_BUILD_PATH}/md5sum.txt 

mkdir -p ${ISO_BUILD_PATH}/efi-temp/${LIVE_BOOT_PATH}

sudo cp -r ${CONF_PATH}/iso/{boot,EFI}/ ${ISO_BUILD_PATH}/efi-temp
sudo cp ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/vmlinuz.efi ${ISO_BUILD_PATH}/efi-temp/${LIVE_BOOT_PATH}
sudo cp ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/initrd.lz ${ISO_BUILD_PATH}/efi-temp/${LIVE_BOOT_PATH}

_TOTALSIZE=$(du -sk ${ISO_BUILD_PATH}/efi-temp/ | awk '{print $1}')
_TOTALSIZE=$(( $_TOTALSIZE * 21 / 20 ))
_BLOCKS=$(( ($_TOTALSIZE + 31) / 32 * 32 ))
echo "EFI boot image needs $_TOTALSIZE Kb, thus allocating $_BLOCKS blocks."

sudo mkfs.msdos -C ${ISO_BUILD_PATH}/boot/efi.img ${_BLOCKS} >/dev/null
sudo mcopy -s -v -i ${ISO_BUILD_PATH}/boot/efi.img ${ISO_BUILD_PATH}/efi-temp/* :: >/dev/null 2>&1
sudo rm -rf ${ISO_BUILD_PATH}/efi-temp

pushd ${ISO_BUILD_PATH} 
find . -type f -print0  | xargs -0 sudo md5sum | grep -v isolinux/ > md5sum.txt 
sed -i '/md5sum.txt/d' md5sum.txt


xorriso -as mkisofs -o ${ISO_FILE} -no-pad \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e boot/efi.img -no-emul-boot \
    -append_partition 2 0x01 boot/efi.img \
    -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
    -appid "Deepin LiveCD" -publisher "Deepin Project <http://www.deepin.org>" \
    -V "$LABEL"  . 

popd >/dev/null
