#!/bin/bash
cd /home/jenkins/pyisobuilder/output/sid/current ;
md5sum  *.iso >  MD5SUM
/home/jenkins/deepin-iso-package-diff.pl /home/jenkins/test/iso/old.iso  /home/jenkins/pyisobuilder/output/sid/current/*amd64.iso >> /home/jenkins/pyisobuilder/output/sid/current/MD5SUM
