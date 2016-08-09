#!/bin/bash

## Deepin LiveCD Build Tool 
## 冷罡华 (Hiweed) <hiweed@gmail.com>
## 张  成 (Stephen) <zhangcheng@linuxdeepin.com>

echo "[CUSTOM] Clean cache directories ..."
sudo rm -rf ${CHROOT_PATH}/var/cache/man/*
sudo rm -rf ${CHROOT_PATH}/var/cache/debconf/*old
sudo rm -rf ${CHROOT_PATH}/var/cache/apt-xapian-index/index*
sudo rm -rf ${CHROOT_PATH}/tmp/*

## files in this dir is downloaded by debootstrap, we should not 
## clean them in chroot env, since APT_ARCHIVE_PATH is mounted
sudo rm -rf ${CHROOT_PATH}/var/cache/apt/archives/*.deb

if [[ -n "${LIGHTDM_SESSION}"  ]]; then
    echo "${LIGHTDM_SESSION}" \
       | sudo tee "${CHROOT_PATH}/etc/lightdm/lightdm.conf" > /dev/null
fi

if [[ -f ${CHROOT_PATH}/usr/share/deepin-installer/hooks/in_chroot/99-setup-apt-sources.job ]] && [[ -f ${DATA_DIR}/99-setup-apt-sources.job ]];then
    sudo rm -f ${CHROOT_PATH}/usr/share/deepin-installer/hooks/in_chroot/99-setup-apt-sources.job
    sudo install -m755 ${DATA_DIR}/99-setup-apt-sources.job ${CHROOT_PATH}/usr/share/deepin-installer/hooks/in_chroot/99-setup-apt-sources.job
fi

if [[ -f ${CHROOT_PATH}/usr/share/deepin-software-center/ui/preference.py ]] && [[ -f ${DATA_DIR}/preference.py ]];then
    sudo rm -f ${CHROOT_PATH}/usr/share/deepin-software-center/ui/preference.py
    sudo install -m644 ${DATA_DIR}/preference.py ${CHROOT_PATH}/usr/share/deepin-software-center/ui/preference.py
fi

# 120s stopping fix
if [[ -f "${CHROOT_PATH}/etc/init/failsafe.conf" ]];then
    sudo sed -i 's/ 20/ 2/' ${CHROOT_PATH}/etc/init/failsafe.conf
    sudo sed -i 's/ 40/ 4/' ${CHROOT_PATH}/etc/init/failsafe.conf
    sudo sed -i 's/ 59/ 5/' ${CHROOT_PATH}/etc/init/failsafe.conf
    sudo sed -i 's/ 120/ 11/' ${CHROOT_PATH}/etc/init/failsafe.conf
fi

if [[ -f ${DATA_DIR}/logo.png ]];then
    echo "Change default logo"
    sudo install -m644 ${DATA_DIR}/logo.png ${CHROOT_PATH}/lib/plymouth/ubuntu_logo.png
fi

if [[ -f ${DATA_DIR}/greeter_logo.png ]];then
    echo "Change greeter logo"
    sudo install -m644 ${DATA_DIR}/greeter_logo.png ${CHROOT_PATH}/usr/share/dde/resources/greeter/images/logo.png
fi

# vim:set ts=8 sts=4 sw=4 ft=sh:
