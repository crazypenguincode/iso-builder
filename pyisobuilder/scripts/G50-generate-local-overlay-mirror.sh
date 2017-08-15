#!/bin/bash

echo "**************G50-generate-local-overlay-mirror.sh********************"
echo "**********************************************************************"
source common

CHROOT_PATH=$1
CONFIG_DIR=$2
CODENAME=$3
DISTRI_CONF=$4
shift 4

prechroot ${CHROOT_PATH}
[[ -d "${CHROOT_PATH}/opt/overlay-mirror" ]] && sudo rm -rf "${CHROOT_PATH}/opt/overlay-mirror"
sudo mkdir -p "${CHROOT_PATH}/opt/overlay-mirror/cache"
sudo mkdir -p "${CHROOT_PATH}/opt/overlay-mirror/conf"
#TODO
echo sudo cp ${DISTRI_CONF} "${CHROOT_PATH}/opt/overlay-mirror/conf/distributions"
chroot_do ${CHROOT_PATH} apt-get update
sudo cp ${DISTRI_CONF} "${CHROOT_PATH}/opt/overlay-mirror/conf/distributions"
chroot_do ${CHROOT_PATH} apt-get -y --force-yes -o Dir::Cache::Archives=/opt/overlay-mirror/cache --download-only install $@

pushd ${CHROOT_PATH}/opt/overlay-mirror
cd ${CHROOT_PATH}/opt/overlay-mirror && sudo reprepro includedeb ${CODENAME} ${CONF_FILE} cache/*.deb
popd >/dev/null
postchroot ${CHROOT_PATH}
sudo rm -rf "${CHROOT_PATH}/opt/overlay-mirror/cache"
sudo rm -rf "${CHROOT_PATH}/opt/overlay-mirror/conf"

LOCAL_SOURCES_LIST="
deb file:///opt/overlay-mirror/ trusty main
"
if [[ ! -f ${CHROOT_PATH}/etc/apt/sources.list.orig ]];then 
    sudo mv ${CHROOT_PATH}/etc/apt/sources.list ${CHROOT_PATH}/etc/apt/sources.list.orig
fi
echo "$LOCAL_SOURCES_LIST" | sudo tee "${CHROOT_PATH}/etc/apt/sources.list" >/dev/null

sudo cp ${CONFIG_DIR}/custom-livecd.conf ${CHROOT_PATH}/etc/init/
