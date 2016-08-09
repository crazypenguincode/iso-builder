#!/bin/bash
## Deepin LiveCD Build Tool 
echo "*****************custom.chroot.sh***************************"


# add i386 architecture
dpkg --add-architecture i386
if [[ -f /etc/apt/sources.list.d/google-chrome.list ]]; then rm -f /etc/apt/sources.list.d/google-chrome.list ; fi

apt-get update
apt-get --no-install-recommends -y --force-yes --allow-unauthenticated upgrade
apt-get --no-install-recommends -y --force-yes --allow-unauthenticated install crossover-15:i386  deepin-wine-uninstaller:i386



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
echo "libmng setting"
touch /usr/lib/x86_64-linux-gnu/libmng.so.1.1.0.10
ln -s /usr/lib/x86_64-linux-gnu/libmng.so.1.1.0.10 /usr/lib/x86_64-linux-gnu/libmng.so.2
ls -la /usr/lib/x86_64-linux-gnu/libmng* 

sed -i "s#;;\(\"AntiVirusScan\" = \)\"\"#\1\"never\"#" /opt/cxoffice/etc/cxoffice.conf

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
echo "installer deepin-license"
#apt-get --no-install-recommends -y --force-yes --allow-unauthenticated install deepin-license-activator

cat /etc/adjtime
sed -i 's/UTC/LOCAL/' /etc/adjtime


echo "[INFO] Disable ntp"
systemctl disable systemd-timesyncd.service
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

rm -f /usr/share/applications/deepin-software-center.desktop

if [ -e /etc/machine-id ];then
    rm -f /etc/machine-id
    : > /etc/machine-id
fi
rm -f /etc/mdadm/mdadm.conf

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

# vim:set ts=8 sts=4 sw=4 ft=sh:
