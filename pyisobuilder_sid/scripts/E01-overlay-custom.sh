#!/bin/bash
echo "***************E01-overlay-custom.sh********************"

source common

CHROOT_PATH=$1
CONFIG_DIR=$2
DATA_DIR=$3
ARCH=$4

[ -f ${CONFIG_DIR}/mkiso.conf ] && source ${CONFIG_DIR}/mkiso.conf
if [ -d ${DATA_DIR}/debs ];then
    echo "[INFO] copy ${DATA_DIR}/debs to build place: ${ARCH}"
    sudo mkdir -p ${CHROOT_PATH}/tmp/debs
    sudo cp -av ${DATA_DIR}/debs/all/*.deb ${CHROOT_PATH}/tmp/debs || true
    sudo cp -av ${DATA_DIR}/debs/${ARCH}/*.deb ${CHROOT_PATH}/tmp/debs
fi
if [ -d ${DATA_DIR}/hooks ];then
    echo "[INFO] copy ${DATA_DIR}/hooks to build place"
    sudo mkdir -p ${CHROOT_PATH}/tmp/hooks
    sudo cp -av ${DATA_DIR}/hooks/* ${CHROOT_PATH}/tmp/hooks
    sudo chmod +x ${CHROOT_PATH}/tmp/hooks/*
fi
# FIXME: should do in common function
prechroot ${CHROOT_PATH}
if [ -d ${CHROOT_PATH}/tmp/debs ];then
    echo "[INFO] Installing overlay debs..." 
    # 直接使用 dpkg -i /tmp/debs/*.debs 会出错
    chroot_do ${CHROOT_PATH} find /tmp/debs -name "*.deb" -exec dpkg -i {} \;
    chroot_do ${CHROOT_PATH} apt-get -f install
    sudo rm -rf ${CHROOT_PATH}/tmp/debs
fi
if [ -d ${CHROOT_PATH}/tmp/hooks ];then
    for i in $(ls ${CHROOT_PATH}/tmp/hooks/);do
	echo "Executing hooks: $i"
	chroot_do ${CHROOT_PATH} /tmp/hooks/$i
    done
    sudo rm -rf ${CHROOT_PATH}/tmp/hooks
fi
postchroot ${CHROOT_PATH}

chroot_source_if_exist ${CONFIG_DIR}/custom.chroot.sh

# Do custom
echo "[CUSTOM] Clean cache directories ..."
sudo rm -rf ${CHROOT_PATH}/var/cache/man/*
sudo rm -rf ${CHROOT_PATH}/var/cache/debconf/*old
sudo rm -rf ${CHROOT_PATH}/var/cache/apt-xapian-index/index*
sudo rm -rf ${CHROOT_PATH}/tmp/*

## files in this dir is downloaded by debootstrap, we should not 
## clean them in chroot env, since APT_ARCHIVE_PATH is mounted
sudo rm -rf ${CHROOT_PATH}/var/cache/apt/archives/*.deb

# 120s stopping fix
if [[ -f "${CHROOT_PATH}/etc/init/failsafe.conf" ]];then
    sudo sed -i 's/ 20/ 2/' ${CHROOT_PATH}/etc/init/failsafe.conf
    sudo sed -i 's/ 40/ 4/' ${CHROOT_PATH}/etc/init/failsafe.conf
    sudo sed -i 's/ 59/ 5/' ${CHROOT_PATH}/etc/init/failsafe.conf
    sudo sed -i 's/ 120/ 11/' ${CHROOT_PATH}/etc/init/failsafe.conf
fi
# don config custom shell
source_if_exist ${CONFIG_DIR}/custom.sh
