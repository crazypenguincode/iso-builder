#!/bin/bash
rm  /home/jenkins/pyisobuilder/output/sid/current/MD5SUM
rm -fr /home/jenkins/test/iso/*
cp /home/jenkins/pyisobuilder/output/sid/current/*amd64*iso   /home/jenkins/test/iso/old.iso || true
