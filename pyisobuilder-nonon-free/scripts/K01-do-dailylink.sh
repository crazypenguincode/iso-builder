#!/bin/bash
OUTPUT_PATH=$1
ARCH=$2
DAILY_DIR=$(dirname ${OUTPUT_PATH})
DAILY_BASE=$(dirname ${DAILY_DIR})
[[ -f ${OUTPUT_PATH} ]] || echo "Daily output path dost not exits"
ln -sf ${OUTPUT_PATH} ${DAILY_BASE}/current/deepin-pro-${ARCH}.iso

