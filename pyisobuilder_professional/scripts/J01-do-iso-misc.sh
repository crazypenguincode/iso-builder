#!/bin/bash
echo "*****************J01-do-iso-misc.sh*****************"
echo "****************************************************"
ISO_BUILD_PATH=$1
CONF_PATH=$2
CONFIGFILE=$3
ARCH=$4

source ${CONFIGFILE}


[[ -d ${ISO_BUILD_PATH}/isolinux ]] && sudo rm -rf ${ISO_BUILD_PATH}/isolinux
[[ -d ${CONF_PATH}/iso/isolinux ]] && cp -r ${CONF_PATH}/iso/isolinux ${ISO_BUILD_PATH}/

[[ -d ${CONF_PATH}/iso/preseed/ ]] && cp -r ${CONF_PATH}/iso/preseed/ ${ISO_BUILD_PATH}/
[[ -d ${CONF_PATH}/iso/iso_root ]] && cp -a ${CONF_PATH}/iso/iso_root/* ${ISO_BUILD_PATH}/
[[ -f ${CONF_PATH}/files_url ]] && wget -i ${CONF_PATH}/files_url -P ${ISO_BUILD_PATH}/

# TODO Generate README.diskdefines
cat > ${ISO_BUILD_PATH}/README.diskdefines <<EOF
#define DISKNAME ${DISTRO_NAME} $VERSION "$CODENAME" - $STATUS $ARCH ($DATE)
#define TYPE binary
#define TYPEbinary 1
#define ARCH $ARCH
#define ARCH${ARCH} 1
#define DISKNUM 1
#define DISKNUM1 1
#define TOTALNUM 0
#define TOTALNUM0 1
EOF

[[ -d "${ISO_BUILD_PATH}/.disk" ]] || mkdir -p "${ISO_BUILD_PATH}/.disk"
echo "[ISO] Generating .disk/base_installable ..."
echo "full_cd/single" > ${ISO_BUILD_PATH}/.disk/cd_type
echo "[ISO] Generating .disk/info ..."
echo "${ISO_INFO}" > ${ISO_BUILD_PATH}/.disk/info
echo "[ISO] Generating .disk/release_notes_url ..."
echo "${RELEASE_URL}" > ${ISO_BUILD_PATH}/.disk/release_notes_url
