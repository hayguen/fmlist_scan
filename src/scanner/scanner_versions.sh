#!/bin/bash

export LC_ALL=C
source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_PATH}" ]; then
  echo "Error: FMLIST_SCAN_PATH ${FMLIST_SCAN_PATH} does not exist!"
  exit 1
fi

pushd "${FMLIST_SCAN_PATH}/../" &>/dev/null
./versions.sh "$@"
popd &>/dev/null
