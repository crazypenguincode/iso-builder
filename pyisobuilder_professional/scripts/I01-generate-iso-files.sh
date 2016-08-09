#!/bin/bash

CHROOT_PATH=$1
ISO_BUILD_PATH=$2
CONFIG_FILE=$3
LIVE_BOOT_PATH=$4
BASEFILEPRE=${6:-filesystem}

source common
source ${CONFIG_FILE}

echo "Regenerating vmlinuz..."
prechroot ${CHROOT_PATH}
chroot_do ${CHROOT_PATH} update-initramfs -u
# run apt-get update temporaily to ensure deepin-software-center, should delete asap.
if [[ ! -z "${ISO_SOURCES_LIST}" ]];then
    echo "[INFO] Detect ISO_SOURCES_LIST exists, override /etc/apt/sources.list"
    echo "${ISO_SOURCES_LIST}" | sudo tee "${CHROOT_PATH}/etc/apt/sources.list" >/dev/null
fi
chroot_do ${CHROOT_PATH} apt-get update
postchroot ${CHROOT_PATH}

# fix lastore list error
[ -d ${CHROOT_PATH}/var/lib/lastore/safecache ] && sudo rm -rf ${CHROOT_PATH}/var/lib/lastore/safecache
[ -x ${CHROOT_PATH}/var/lib/lastore/build_safecache.sh ] && chroot_do ${CHROOT_PATH} /var/lib/lastore/build_safecache.sh

#[ -f ${CHROOT_PATH}/etc/apt/apt.conf.d/99translations ] && sudo rm -rf ${CHROOT_PATH}/etc/apt/apt.conf.d/99translations
#sudo ln -sf ../run/resolvconf/resolv.conf ${CHROOT_PATH}/etc/resolv.conf

sudo mksquashfs ${CHROOT_PATH} ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/${BASEFILEPRE}.squashfs -comp xz

sudo du -sx --block-size=1 ${CHROOT_PATH} | cut -f1 > ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/${BASEFILEPRE}.size

chroot_do ${CHROOT_PATH} dpkg-query -W --showformat='${Package} ${Version}\n' \
    > ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/${BASEFILEPRE}.manifest
sudo cp ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/${BASEFILEPRE}.manifest{,-desktop}

for i in $UBIQUITY_REMOVE;do
    sudo sed -i /$i/d ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/${BASEFILEPRE}.manifest-desktop
done
VMLINUZ_FILE=$(ls -r1 --sort=version ${CHROOT_PATH}/boot/vmlinuz-* | head -n 1)
[[ -f ${VMLINUZ_FILE} ]] && sudo install -m644 ${VMLINUZ_FILE} ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/vmlinuz || exit 101
[[ -f ${VMLINUZ_FILE} ]] && sudo install -m644 ${VMLINUZ_FILE} ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/vmlinuz || exit 101
INITRD_FILE=$(ls -r1 --sort=version ${CHROOT_PATH}/boot/initrd.img-* | head -n 1)
[[ -f ${INITRD_FILE} ]]  && sudo cp ${INITRD_FILE} ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/initrd.lz || exit 101

