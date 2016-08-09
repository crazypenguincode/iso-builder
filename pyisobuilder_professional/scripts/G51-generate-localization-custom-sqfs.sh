#!/bin/bash
# Depends unionfs-utils
# fix me soon, work not right
echo "**************G51-generate-localization-custom-sqfs.sh***********************"
echo "*****************************************************************************"
trap clean_workspace ERR TERM EXIT KILL

source common

CHROOT_PATH=$1
ISO_BUILD_PATH=$2
LIVE_BOOT_PATH=$3
shift 3
LANGS=$@

base_chroot_path=${CHROOT_PATH}

delta_file() {
    local L=$1
    local BASEROOT=$2
    shift 2
    local packages=$@
    # should work with casper packages. debian should be in live
    local sqfs_file="overlay-deepin-${L}.squashfs"
    #[[ -e ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/$sqfs_file ]] && { echo "[WARING] Job has done before.Exit..." ; return; }
    local overlay_filesytem=${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/${L}
    local fake_chroot_path=${overlay_filesytem}-fakeroot
    [[ -d $fake_chroot_path ]] && { echo "[WARING] Job has done before.Exit..." ; return; }
    mkdir -p $overlay_filesytem
    mkdir -p $fake_chroot_path
    sudo unionfs-fuse -o cow -o noinitgroups -o default_permissions -o allow_other -o use_ino -o suid $overlay_filesytem=RW:$BASEROOT=RO "$fake_chroot_path"
    prechroot $fake_chroot_path
    chroot_do $fake_chroot_path apt-get update
    chroot_do $fake_chroot_path apt-get install \
        --no-install-recommends -y --force-yes --allow-unauthenticated \
        $packages
    # fix wps font set, please remove soon.
    if [[ -f $fake_chroot_path/opt/kingsoft/wps-office/office6/mui/zh_CN/l10n/common.cfg ]];then
	sudo sed -i '1,3s/宋体/文泉驿微米黑/g' $fake_chroot_path/opt/kingsoft/wps-office/office6/mui/zh_CN/l10n/common.cfg
	sudo sed -i '4s/微软雅黑/文泉驿微米黑/g' $fake_chroot_path/opt/kingsoft/wps-office/office6/mui/zh_CN/l10n/common.cfg
    fi
    postchroot $fake_chroot_path
}

umount_all() {
    CUR_DIR=$(readlink -f $1)
    declare -a queue
    queue=("language-pack" "office")
    for var in ${queue[@]};do
	lines=$(mount | awk '{print $3}' | grep ${CUR_DIR} | grep ${var} | sort -r)
	for dir in ${lines};do
	    sudo fusermount -u $dir
	done
    done
}

gen_overlay() {
    LANG=$1
    echo "filesystem.squashfs" > ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/filesystem.${LANG}.module
    case $LANG in
        zh_CN)
    	echo "[INFO] Generate $LANG --> kingsoftoffice"
        delta_file office-kingsoftoffice ${base_chroot_path} wps-office
    	echo "overlay-deepin-office-kingsoftoffice.squashfs" >> ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/filesystem.${LANG}.module
    	baseroot=${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/office-kingsoftoffice-fakeroot
    	delta_file language-pack-zhcn ${baseroot} "fcitx-sogoupinyin-uk thunderbird-locale-zh-hans"
    	echo "overlay-deepin-language-pack-zhcn.squashfs" >> ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/filesystem.${LANG}.module
        ;;
        en_US)
    	echo "[INFO] Generate $LANG --> libreoffice"
        delta_file office-libreoffice ${base_chroot_path} "libreoffice-calc libreoffice-gnome libreoffice-writer libreoffice-impress"
    	echo "overlay-deepin-office-libreoffice.squashfs" >> ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/filesystem.${LANG}.module
    	echo "[INFO] Generate $LANG --> dde-meta-en ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}"
    	baseroot=${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/office-libreoffice-fakeroot
    	delta_file language-pack-enus ${baseroot} "pidgin pidgin-libnotify"
    	echo "overlay-deepin-language-pack-enus.squashfs" >> ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/filesystem.${LANG}.module
        ;;
        zh_TW)
    	echo "[INFO] Generate $LANG --> kingsoftoffice"
        delta_file office-kingsoftoffice ${base_chroot_path} "wps-office thunderbird-locale-zh-hant" 
    	echo "overlay-deepin-office-kingsoftoffice.squashfs" >> ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/filesystem.${LANG}.module
        ;;
        *)
    	echo "Not support $LANG"
    	;;
    esac
}

gen_sqfs() {
    for dir in $(find ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/ -mindepth 1 -maxdepth 1 -type d | grep -v fakeroot);do
	#so ugly to use basename
	echo " ===> Generate ${dir} -> $(dirname ${dir})/overlay-deepin-$(basename ${dir}).squashfs"
	local sqfs_file=overlay-deepin-$(basename "${dir}").squashfs
	for i in $(ls $dir/var/lib | grep -v dpkg); do sudo rm -rf $dir/var/lib/$i; done
	sudo rm -rf $dir/var/cache
	sudo rm -rf $dir/var/log
	sudo rm -rf $dir/run
	sudo rm -rf $dir/tmp
	sudo rm -rf $dir/.unionfs
	find $dir -name "*.cache" -exec sudo rm -f \{\} \;
	sudo mksquashfs $dir ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH}/$sqfs_file -comp xz
    done
}
clean_workspace() {
    # bad action. fix me soon.
    umount_all ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH} || true
    echo "[XXOO] Again to Make sure clean"
    umount_all ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH} || true
    echo "[OOXX] Again to Make sure clean"
    echo "  ==> Cleaning mounting directories..."
    find ${ISO_BUILD_PATH}/${LIVE_BOOT_PATH} -mindepth 1 -maxdepth 1 -type d -exec sudo rm -rf \{\} \;
}
while [ -n "$*" ];do
    echo "[INFO] Genereating overlay squashfs for $1..."
    gen_overlay $1
    shift
done

echo "[INFO] Cheers, Seem works all right!"
gen_sqfs
echo "[INFO] Lucky, Clean all unused files"
clean_workspace
