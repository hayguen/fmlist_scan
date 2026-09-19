#!/bin/bash

export LC_ALL=C
source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_PATH}" ]; then
  echo "Error: FMLIST_SCAN_PATH ${FMLIST_SCAN_PATH} does not exist!"
  exit 1
fi

if [ -s "${FMLIST_SCAN_RAM_DIR}/tef6686_version" ]; then
  echo "tef6686        $(cat "${FMLIST_SCAN_RAM_DIR}/tef6686_version")"
fi

pushd "${FMLIST_SCAN_PATH}/../" &>/dev/null
./versions.sh "$@"
popd &>/dev/null
