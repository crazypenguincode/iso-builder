#!/bin/bash
echo "****************************************"
echo "G51-generate-cdrom-repository.sh"

source common

CHROOT_PATH=$1
CONFIG_DIR=$2
CODENAME=$3
ISOBUILDPATH=$4
DISTRI_CONF=$5
shift 5
PACKAGES=$@

prechroot ${CHROOT_PATH}
[[ -d "${CHROOT_PATH}/opt/overlay-mirror" ]] && sudo rm -rf "${CHROOT_PATH}/opt/overlay-mirror"
sudo mkdir -p "${CHROOT_PATH}/opt/overlay-mirror/cache"
sudo mkdir -p "${CHROOT_PATH}/opt/overlay-mirror/conf"
#TODO
echo sudo cp ${DISTRI_CONF} "${CHROOT_PATH}/opt/overlay-mirror/conf/distributions"
chroot_do ${CHROOT_PATH} apt-get update
sudo cp ${DISTRI_CONF} "${CHROOT_PATH}/opt/overlay-mirror/conf/distributions"
for p in ${PACKAGES};do 
    chroot_do ${CHROOT_PATH} apt-get -y --force-yes -o Dir::Cache::Archives=/opt/overlay-mirror/cache --download-only install ${p}
done

pushd ${CHROOT_PATH}/opt/overlay-mirror
cd ${CHROOT_PATH}/opt/overlay-mirror && sudo reprepro includedeb ${CODENAME} ${CONF_FILE} cache/*.deb
popd >/dev/null
postchroot ${CHROOT_PATH}
sudo cp -ar  "${CHROOT_PATH}/opt/overlay-mirror/dists" "${ISOBUILDPATH}"
sudo cp -ar "${CHROOT_PATH}/opt/overlay-mirror/pool" "${ISOBUILDPATH}"
sudo rm -rf "${CHROOT_PATH}/opt/overlay-mirror"
