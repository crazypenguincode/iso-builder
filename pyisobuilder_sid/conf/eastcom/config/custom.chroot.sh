#!/bin/bash
## Deepin LiveCD Build Tool 
## 冷罡华 (Hiweed) <hiweed@gmail.com>
## 张  成 (Stephen) <zhangcheng@linuxdeepin.com>

# update system
# add i386 architecture
apt-get update
apt-get --no-install-recommends -y --force-yes --allow-unauthenticated upgrade

if [[ "$(dpkg-architecture -qDEB_BUILD_ARCH)" == "amd64" ]];then
    apt-get --no-install-recommends -y --force-yes --allow-unauthenticated install fwts
fi

if [[ -d /tmp/debs ]];then dpkg -i /tmp/debs/*.deb; fi
# clean all source.d 
find /etc/apt/sources.list.d/ -name "*.list" -exec rm \{\} \;

apt-get --no-install-recommends -y --force-yes --allow-unauthenticated -f install 
# clean apt cache
echo "Deleting caches"
apt-get clean
rm /var/lib/apt/lists/*_dists*

cat >> /etc/default/grub <<EOF
GRUB_RECORDFAIL_TIMEOUT="1"
EOF


echo "[CUSTOM][CHROOT] Deleting unused locale files ..."
cat > /etc/locale.nopurge <<EOF
MANDELETE
DONTBOTHERNEWLOCALE
SHOWFREEDSPACE
en_US                                                                               
en_US.ISO-8859-15                                                                   
en_US.UTF-8                                                                         
zh_CN                                                                               
zh_CN.GB18030                                                                       
zh_CN.GBK                                                                           
zh_CN.UTF-8                                                                         
zh_HK                                                                               
zh_HK.UTF-8                                                                         
zh_SG                                                                               
zh_SG.GBK                                                                           
zh_SG.UTF-8                                                                         
zh_TW                                                                               
zh_TW.EUC-TW                                                                        
zh_TW.UTF-8   
EOF

cat > /usr/share/deepin-default-settings/desktop-version <<EOF
[Release]
Version=ATM
Type=Customized
Type[zh_CN]=定制版
EOF

cat > /etc/timezone <<EOF
Asia/Shanghai
EOF
dpkg-reconfigure --frontend noninteractive tzdata

echo "[CUSTOM][CHROOT] Deleting unused lanaguages ..."
LANGLIST='am ar ast be bg bn bs ca cs da de dz el eo es et eu fa fi fr ga gl gu he hi hr hu id is it ja ka kk km ko ku lt lv mk ml mr  nb ne nl nn no pa pl pt pt_br ro ru sk sl sq sr sv ta te th tl tr uk vi'
for i in $LANGLIST
do
    sed -i /$i\.utf-8:/d /var/cache/debconf/templates.dat
done

# remove xterm
apt-get purge -y --force-yes xterm 

# change pam passwd minlen to 1
sed -i -l 25 's/obscure/minlen=1/' /etc/pam.d/common-password

# set default logo
dpkg-divert --rename --quiet --remove /lib/plymouth/ubuntu_logo.png

update-alternatives --install /lib/plymouth/themes/default.plymouth default.plymouth \
	/lib/plymouth/themes/solar/solar.plymouth 300 

# remove unneed dde-guide execute file
rm -f /usr/lib/deepin-daemon/dde-guide
touch /etc/skel/.config/not_first_run_dde

#remove Welcome to Deepin 2014.3
rm -f /etc/update-motd.d/00-header
rm -f /etc/update-motd.d/10-help-text

# modify UTC 8 hours
sed -i  's/UTC=no/UTC=yes/g' /etc/default/rcS

# disable casper autologin 
#rm -f /usr/share/initramfs-tools/scripts/casper-bottom/15autologin 
apt-get purge -y --force-yes ubuntu-minimal resolvconf 

# 生成locale免得update-initramfs报warning
locale-gen --purge --no-archive
## 最后需要 update-initramfs
update-initramfs -u

# vim:set ts=8 sts=4 sw=4 ft=sh:
