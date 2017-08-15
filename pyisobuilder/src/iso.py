#! /usr/bin/env python2
# -*- coding: utf-8 -*-
#

import os
import glob
import subprocess
import datetime

def is_mounted(path, fstype='tmpfs'):
    with open('/etc/mtab', 'r') as mtab:
        for line in mtab.readlines():
            if path in line and fstype in line:
                return True
    return False


class IsoBuilder:
    """
    Depends on debootstrap squashfs-tools genisoiamge syslinux lzma mktorrent zsync
    live_boot should be "casper" and "live" as ubuntu -> casper and debian -> live
    """
    def __init__(self, isobuildpath, datadir, configdir, codename, arch, debootstrap, logfile,live_boot='casper', tmpfs_size=None):
        self.isobuildpath = isobuildpath 
        self.datadir = datadir
        self.configdir = configdir
        self.config = os.path.join(self.configdir, 'mkiso.conf')
        self.codename = codename
        self.arch = arch
        self.directory = debootstrap
        self.label = 'Deepin_{}'.format(datetime.datetime.now().strftime("%Y-%m-%d"))
        self.squashfs_file = None
        self.tmpfs_size = tmpfs_size
        self.live_boot = live_boot
        if logfile is not None:
            self.fdout = open(logfile, 'a')
        else:
            self.fdout = None

    def create_debootstrap(self, debootstrap_mirror="http://packages.linuxdeepin.com/ubuntu", overlay_packages=None):
        if not os.path.exists(self.directory):
            os.makedirs(self.directory)
        if self.tmpfs_size and not is_mounted(self.directory):
            command = 'sudo mount -t tmpfs -o size=%s tmpfs %s' % (self.tmpfs_size, self.directory)
            subprocess.check_call(command.split())
        default_overlay_packages = {'dbus','wget'}
        if overlay_packages is None:
            overlay_packages = default_overlay_packages
        else:
            overlay_packages = default_overlay_packages.union(overlay_packages)

        include_packages = ','.join(overlay_packages)

        command = "sudo debootstrap --no-check-gpg --arch={arch} --include={include_packages} {codename} {directory} {debootstrap_mirror}".format(**{"arch": self.arch, "include_packages": include_packages, "codename": self.codename, "directory": self.directory, "debootstrap_mirror":debootstrap_mirror})
        print "Build base system starting"
        subprocess.check_call(command, stdout=self.fdout, shell=True)

    def make_desktop(self, misc_packages=None):
        scripts = glob.glob('scripts/D0*.sh')
        for script in scripts:
            subprocess.check_call([script, self.directory, self.config], stdout=self.fdout)

        if misc_packages is not None:
            misc_packages = ' '.join(misc_packages)
            print misc_packages
            subprocess.check_call(['scripts/D99-custom-finally.sh', self.directory, misc_packages], stdout=self.fdout)

    def custom_desktop(self):
        for script in glob.glob('scripts/E*.sh'):
            subprocess.check_call([script, self.directory, self.configdir, self.datadir, self.arch], stdout=self.fdout)

    def prepare_cdrom_repository(self, include_packages=None):
        """
        Creates missing file in the overlay
        """
        if include_packages is None:
            pass
        else:
            packages=" ".join(include_packages)

        if self.arch != "amd64":
            arches = self.arch
        else:
            arches = self.arch +' '+'i386'
        DISTRIBUTIONS_TEMPLATE="""Origin: LinuxDeepin
Label: Overlay
Codename: {codename}
Version: dummy
Architectures: {arch}
Components: main
Description: Linuxdeepin overlay mirror
""".format(**{"codename":self.codename, "arch":arches})
        distributions_file = os.path.join(self.configdir,"overlay-distributions-%s" % self.arch)
        with open(distributions_file,'w') as fp:
            fp.write(DISTRIBUTIONS_TEMPLATE)
        subprocess.check_call(['scripts/G51-generate-cdrom-repository.sh', self.directory, self.configdir, self.codename, self.isobuildpath, distributions_file, packages], stdout=self.fdout)

    def prepare_overlay_squashfs(self, langs=['zh_CN', 'en_US', 'zh_TW'], dest=None):
        if not dest:
            dest = self.live_boot
        if not os.path.exists(os.path.join(self.isobuildpath,dest)):
            os.makedirs(os.path.join(self.isobuildpath,dest))
        if self.live_boot == "live":
            sqfs_script = 'scripts/G51-generate-localization-custom-sqfs.sh.live'
        else:
            sqfs_script = 'scripts/G51-generate-localization-custom-sqfs.sh'
        cmd = [sqfs_script, self.directory, self.isobuildpath, dest] 
        for lang in langs:
            cmd.append(lang)
        subprocess.check_call(cmd, stdout=self.fdout)

    def prepare_iso(self):
        if not os.path.exists(os.path.join(self.isobuildpath,self.live_boot)):
            os.makedirs(os.path.join(self.isobuildpath,self.live_boot))
        subprocess.check_call(['scripts/I01-generate-iso-files.sh',self.directory, self.isobuildpath, self.config, self.live_boot, 'filesystem'], stdout=self.fdout)

    #def make_squashfs(self, name="filesystem.squashfs"):
    #    assert os.path.isdir(self.directory), "mksquashfs only works on directory!"
    #    if not os.path.exists(os.path.join(self.isobuildpath,self.live_boot)):
    #        os.makedirs(os.path.join(self.isobuildpath,self.live_boot))
    #    sqimg = os.path.join(self.isobuildpath, self.live_boot,name)
    #    print "Generating SquashFS image for %s" % self.directory
    #    print "Creating SquashFS iamge. This may take some time..."
    #    #command = "sudo mksquashfs %s %s -noappend -comp xz -Xbcj x86" % (self.directory, sqimg)
    #    command = "sudo mksquashfs %s %s -noappend -comp xz" % (self.directory, sqimg)
    #    if not os.path.isfile(sqimg):
    #        subprocess.check_call(command.split(), stdout=self.fdout)
    #    self.squashfs_file = sqimg

    def make_iso(self, publisher="Deepin Project <http://www.deepin.com>", application="Linuxdeepin LiveCD", label="LinuxDeepin 2014", enable_efi=True, enable_ia32efi=False, imgname='/tmp/output.iso'):
        if not os.path.exists(os.path.dirname(imgname)):
            os.makedirs(os.path.dirname(imgname))
        subprocess.check_call(['scripts/J01-do-iso-misc.sh', self.isobuildpath, self.configdir, self.config, self.arch], stdout=self.fdout)
        if self.arch == 'amd64' and enable_efi is True:
            subprocess.check_call(['scripts/J50-do-efi-boot.sh',self.configdir, self.isobuildpath, imgname, label,self.live_boot], stdout=self.fdout)
        elif self.arch == 'i386' and enable_ia32efi is True:
            subprocess.check_call(['scripts/J50-do-ia32-efi-boot.sh',self.configdir, self.isobuildpath, imgname, label,self.live_boot], stdout=self.fdout)
        else:
            subprocess.check_call(['scripts/J51-do-regular-boot.sh',self.isobuildpath, imgname], stdout=self.fdout)

    def make_dailylink(self, output_path, arch):
        subprocess.check_call(['scripts/K01-do-dailylink.sh', output_path, arch])

    def clean(self):
        if self.fdout is not None:
            self.fdout.close()
        subprocess.check_call(['scripts/clean.sh', self.directory, self.isobuildpath])

