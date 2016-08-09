#!/bin/bash
# Don't change the filename or FIXME.
CLEAN_PATH=$@

source common

for dir in ${CLEAN_PATH};do
	if [ -x ${dir}/bin/sh ];then
		postchroot ${dir}
	fi
	sudo rm -rf ${dir}/* || true
done
exit 0
