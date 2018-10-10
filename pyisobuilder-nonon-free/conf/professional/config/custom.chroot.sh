#!/bin/bash
## Deepin LiveCD Build Tool 
echo "*****************custom.chroot.sh***************************"

# add i386 architecture
echo "remove /usr/bin/bash"
ls -la /usr/bin/bash
dpkg --add-architecture i386
if [[ -f /etc/apt/sources.list.d/google-chrome.list ]]; then rm -f /etc/apt/sources.list.d/google-chrome.list ; fi

#disable google-chrome-stable hardware acceleration
echo "disable google-chrome hardware acceleration"
mkdir -p /etc/opt/chrome/policies/recommended
echo -e "{\n\t\"HardwareAccelerationModeEnabled\": false\n}" > /etc/opt/chrome/policies/recommended/disable-hardware-acceleration.json


apt-get update
#apt-get --no-install-recommends -y --force-yes --allow-unauthenticated upgrade
apt-get --no-install-recommends -y --force-yes --allow-unauthenticated install deepin-wine-uninstaller:i386
apt-get -y --force-yes --allow-unauthenticated install samba attr logrotate samba-dsdb-modules samba-vfs-modules
#samsung-print
apt-get --no-install-recommends -y --force-yes --allow-unauthenticated install samsung-print
apt-get --no-install-recommends -y --force-yes --allow-unauthenticated install grub-themes-deepin

# deepin.com.qq.im　缺少依赖包安装
#apt-get -y --force-yes --allow-unauthenticated install deepin-fonts-wine i965-va-driver:i386 libasound2-plugins:i386 libavcodec57:i386 libavresample3:i386 libavutil55:i386 libcairo2:i386 libcrystalhd3:i386 libfontconfig1:i386 libgomp1:i386 libgsm1:i386 libjack-jackd2-0:i386 libmp3lame0:i386 libnuma1:i386 libopenjp2-7:i386 libopus0:i386 liborc-0.4-0:i386 libpixman-1-0:i386 libsamplerate0:i386 libschroedinger-1.0-0:i386 libshine3:i386 libsnappy1v5:i386 libsoxr0:i386 libspeex1:i386 libspeexdsp1:i386 libswresample2:i386 libtheora0:i386 libtwolame0:i386 libva-drm1:i386 libva-x11-1:i386 libva1:i386 libvdpau-va-gl1:i386 libvdpau1:i386 libvpx4:i386 libwavpack1:i386 libwebp6:i386 libwebpmux2:i386 libx264-148:i386 libx265-95:i386 libxcb-render0:i386 libxcb-shm0:i386 libxvidcore4:i386 libzvbi0:i386 mesa-va-drivers:i386 mesa-vdpau-drivers:i386 va-driver-all:i386 vdpau-driver-all:i386 p11-kit-modules:i386 

# 密匙环问题
#apt-get --no-install-recommends -y --force-yes --allow-unauthenticated install seahorse-daemon

# install empty directory to prevent xdg-desktop-menu install *.desktop to fail (wps need it.)
[[ ! -d /usr/share/desktop-directories ]] && install -dm755 /usr/share/desktop-directories

#apt-get --no-install-recommends -y --force-yes --allow-unauthenticated install deepinwine-qq
if [[ -f /opt/kingsoft/wps-office/office6/mui/zh_CN/l10n/common.cfg ]];then
    sed -i '1,3s/宋体/文泉驿微米黑/g' $fake_chroot_path/opt/kingsoft/wps-office/office6/mui/zh_CN/l10n/common.cfg
    sed -i '4s/微软雅黑/文泉驿微米黑/g' $fake_chroot_path/opt/kingsoft/wps-office/office6/mui/zh_CN/l10n/common.cfg
fi

arch=$(dpkg-architecture -qDEB_BUILD_ARCH)
#586 kernel has bug and some problem.
case $arch in 
    amd64)
	_arch=amd64
	;;
    i386)
	_arch=686-pae
	;;
    *)
	echo "[Error] $arch is not supported!"
	exit 101
	;;
esac

if [ "$arch" = "i386" ];then
    apt-get --no-install-recommends -y --force-yes --allow-unauthenticated install libc6-i686
fi

apt-get --no-install-recommends -y --force-yes --allow-unauthenticated install linux-image-deepin-${_arch} linux-headers-deepin-${_arch}
apt-get --no-install-recommends -y --force-yes --allow-unauthenticated install bcmwl-kernel-source 

# fix aufs missing in 4.0 kernel
_kernel_version=$(dpkg-query -W -f='${Version}' linux-image-deepin-${_arch})
case $_kernel_version in 
    4.*)
	echo "[WARN]Detect installer kernel version >> 4.0, Set default UNIONTYPE to overlay."
	sed -i '269s/UNIONTYPE="aufs"/UNIONTYPE="overlay"/' /lib/live/boot/9990-cmdline-old
	;;
esac

# fix fat mount with IO charset error
if ! grep -q 'manual_add_modules nls_ascii' /usr/share/initramfs-tools/hooks/live;then 
    sed -i '/manual_add_modules vfat/i\manual_add_modules nls_ascii' /usr/share/initramfs-tools/hooks/live
fi


echo "[INFO] Enable ntp"
systemctl enable systemd-timesyncd.service
echo "[INFO] Disable dispatcher service"
systemctl disable NetworkManager-dispatcher.service || true

# clean apt cache
echo "[INFO] Deleting caches"
apt-get clean
rm /var/lib/apt/lists/*_dists*

# remove unused desktop file.
rm -f /usr/share/applications/vim.desktop
rm -f /etc/apt/sources.list.d/*
# keep password blank
sed -i 's/_PASSWORD=".*"/_PASSWORD="U6aMy0wojraho"/' /lib/live/config/0030-user-setup
sed -i -r -e "s|^#.*greeter-session=.*\$|greeter-session=lightdm-deepin-greeter|" \
    -e "s|^#.*user-session=.*\$|user-session=deepin|" \
    /etc/lightdm/lightdm.conf

#dpkg-reconfigure --frontend noninteractive tzdata

[[ -x /usr/bin/updatedb ]] && /usr/bin/updatedb
[[ -x /usr/sbin/update-command-not-found ]] && /usr/sbin/update-command-not-found

sed -i "s#;;\(\"AntiVirusScan\" = \)\"\"#\1\"never\"#" /opt/cxoffice/etc/cxoffice.conf

#sed  -i 's#-n\ -o\ move#-n --move#'   /usr/share/initramfs-tools/scripts/init-bottom/udev
#sed -i "s#After=local-fs.target#\#After=local-fs.target#" /lib/systemd/system/live-config.service

rm -f /usr/share/applications/deepin-software-center.desktop
echo "lastore-tools metadata "
#lastore-tools metadata -u

if [ -e /etc/machine-id ];then
    rm -f /etc/machine-id
    : > /etc/machine-id
fi
rm -f /etc/mdadm/mdadm.conf

#add iso md5sum check
cat >/usr/bin/deepinisocheck.sh<<EOF
#!/bin/bash
declare -i PERCENT=0
(
if [ -f /lib/live/mount/medium/md5sum.txt ];then
    num=0
    while read line
    do
	if [ \$PERCENT -le 100 ];then
	    echo "XXX"
	    echo "check \${line##* }..."
	    echo "XXX"
	    md5=\`md5sum /lib/live/mount/medium/\${line##* }\`
	    if [ "\${md5%% *}" != "\${line%% *}" ];then
		echo "XXX"
		echo "check \${line##* } error!" >/tmp/check_failed
		echo "XXX"
		break
	    fi
	    echo \$PERCENT
	fi
	let num+=1
	if [ "\$num" == "5" ];then
	    let PERCENT+=1;
	    num=0
	fi
    done < /lib/live/mount/medium/md5sum.txt
fi
) | dialog --title "check md5..." --gauge "starting to check md5..." 6 100 0
if [ -f /tmp/check_failed ];then
    value=\`cat /tmp/check_failed\`
    dialog --title "check md5" --msgbox "checksum failed \n  \$value "  10 60
else
    dialog --title "check md5" --msgbox "checksum success"  10 20
fi
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger
EOF
chmod +x /usr/bin/deepinisocheck.sh

# remove xterm
apt-get purge -y --force-yes xterm 
apt-get purge -y --force-yes rsyslog
# set plymouth theme
# plymouth-set-default-theme solar

# change pam passwd minlen to 1
sed -i -l 25 's/obscure/minlen=1/' /etc/pam.d/common-password
apt-get autoremove -y

# 生成locale免得update-initramfs报warning
locale-gen --purge --no-archive

## 最后需要 update-initramfs
update-initramfs -u

# 添加lastore-daemon需要的metadata
wget -P /var/lib/lastore/tree/ http://pools.corp.deepin.com/objects.tar.gz
tar -zxvf /var/lib/lastore/tree/objects.tar.gz -C /var/lib/lastore/tree/
lastore-tools metadata -u
rm /var/lib/lastore/tree/objects.tar.gz
du -sh /var/cache/fontconfig
echo "make fontcache"
fc-cache
# vim:set ts=8 sts=4 sw=4 ft=sh:
echo "settings oem"
