#!/bin/bash
# Don't change the filename or FIXME.
CHROOT_PATH=$1
shift

source common
prechroot ${CHROOT_PATH}
chroot_do ${CHROOT_PATH} apt-get install \
    --no-install-recommends -y --force-yes \
    --allow-unauthenticated \
    $@

#chroot_do ${CHROOT_PATH} aptitude unmarkauto ~M

postchroot ${CHROOT_PATH}
