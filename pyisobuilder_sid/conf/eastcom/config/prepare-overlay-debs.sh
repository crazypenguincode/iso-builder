#!/bin/bash

echo "Prepare to move debs from ${DATA_DIR}/debs -> ${CHROOT_PATH}/tmp/debs"
if [[ -d ${DATA_DIR}/debs ]];then
    mkdir -p ${CHROOT_PATH}/tmp/debs
    [[ -d ${DATA_DIR}/debs/all ]] && sudo cp -av ${DATA_DIR}/debs/all/*.deb ${CHROOT_PATH}/tmp/debs
    [[ -d ${DATA_DIR}/debs/${ARCH} ]] && sudo cp -av ${DATA_DIR}/debs/${ARCH}/*.deb ${CHROOT_PATH}/tmp/debs
else
    echo "No 'debs' exits."
fi

echo "Prepare to do custom config fiels"

