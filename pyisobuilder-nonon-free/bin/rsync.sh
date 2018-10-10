#!/bin/bash
rsync -rtlvpL --progress  /home/jenkins/pyisobuilder/output/sid/   iso:/cdimage/iso/daily-live-pro/
