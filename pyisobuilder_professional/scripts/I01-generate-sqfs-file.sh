#!/bin/bash

CHROOT_PATH=$1
ISO_BUILD_PATH=$2
LIVE_PATH=$3
SQFSNAME=${4:-filesystem}

source common


sudo mksquashfs ${CHROOT_PATH} ${ISO_BUILD_PATH}/${LIVE_PATH}/${SQFSNAME}.squashfs -comp xz

sudo du -sx --block-size=1 ${CHROOT_PATH} | cut -f1 > ${ISO_BUILD_PATH}/${LIVE_PATH}/${SQFSNAME}.size

chroot_do ${CHROOT_PATH} dpkg-query -W --showformat='${Package} ${Version}\n' \
    > ${ISO_BUILD_PATH}/${LIVE_PATH}/${SQFSNAME}.manifest
