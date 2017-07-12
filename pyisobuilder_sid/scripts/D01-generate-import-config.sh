#!/bin/bash
CHROOT_PATH=$1
CONFIG=$2

source common
source ${CONFIG} || exit 104

prechroot ${CHROOT_PATH} 
echo "${SOURCES_LIST}" | sudo tee "${CHROOT_PATH}/etc/apt/sources.list" >/dev/null
echo "${APT_PREFERENCES}" | sudo tee "${CHROOT_PATH}/etc/apt/preferences" >/dev/null
echo 'Acquire::Languages "none";' | sudo tee "${CHROOT_PATH}/etc/apt/apt.conf.d/99translations" >/dev/null
wget -q "${DEEPIN_APTKEY_URL}" -O- | chroot_do ${CHROOT_PATH} apt-key add - > /dev/null
echo "**********************************************"
echo "***********D01-generate-import-config.sh***********************************"
echo "**********************************************"

[ ! -z ${MULTIARCH} ] && chroot_do ${CHROOT_PATH} dpkg --add-architecture ${MULTIARCH}

chroot_do ${CHROOT_PATH} apt-get --allow-unauthenticated update || true
chroot_do ${CHROOT_PATH} apt-get --no-install-recommends --allow-unauthenticated -y --force-yes dist-upgrade || true
#sometime go wrong like unmet dependence.Try to fix it.
chroot_do ${CHROOT_PATH} apt-get --no-install-recommends --allow-unauthenticated -y --force-yes -f install 
chroot_do ${CHROOT_PATH} apt-get --no-install-recommends --allow-unauthenticated -y --force-yes dist-upgrade || true

CONFIGPATH=$(dirname ${CONFIG})
if [ ! -z "${DEFAULT_PUBLIC_PACKAGES}" ];then
    for pkg in ${DEFAULT_PUBLIC_PACKAGES};do
        echo "${pkg}" | sudo tee -a ${CHROOT_PATH}/root/packages.list.tmp
    done
fi

if [ -r $CONFIGPATH/packages.list ];then
    echo "[INFO] Found packages.list file. Add packages DEFAULT_PUBLIC_PACKAGES"
    cat ${CONFIGPATH}/packages.list | sed '/^\s*$/d' | sed '/^#.*$/d' | sudo tee -a ${CHROOT_PATH}/root/packages.list.tmp
fi
sudo cat ${CHROOT_PATH}/root/packages.list.tmp | uniq | sudo tee ${CHROOT_PATH}/root/packages.list
sudo rm -f ${CHROOT_PATH}/root/packages.list.tmp

echo "[INFO] Install DEFAULT_PUBLIC_PACKAGES"
set -e
chroot_do ${CHROOT_PATH} xargs --arg-file=/root/packages.list apt-get \
    --no-install-recommends -y --force-yes \
    --allow-unauthenticated install 
set +e
sudo rm -rf ${CHROOT_PATH}/root/packages.list
echo "[INFO] Install DEFAULT_PUBLIC_PACKAGES Done"

chroot_do ${CHROOT_PATH} aptitude unmarkauto ~M
chroot_do ${CHROOT_PATH} apt-get update
chroot_do ${CHROOT_PATH} apt-get install \
    --no-install-recommends -y --force-yes \
    --allow-unauthenticated \
     ${LIVE_ONLY_PUBLIC_PACKAGES}
postchroot ${CHROOT_PATH} 
