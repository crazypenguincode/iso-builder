#!/bin/bash
OUTPUT_PATH=$1

DAILY_DIR=$(dirname ${OUTPUT_PATH})
DAILY_BASE=$(basename ${OUTPUT_PATH})
[[ -d ${OUTPUT_PATH} ]] || echo "Daily output path dost not exits"
ln -snf ${DAILY_BASE} ${DAILY_DIR}/current

