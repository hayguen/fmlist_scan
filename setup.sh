#!/bin/bash

#export FMLIST_SCAN_USER="hayguen"   # default user "pi"
#export FMLIST_SCAN_RASPI="0"       # default "1" if Raspberry Pi hardware
#export FMLIST_SCAN_GPS_COORDS="48.885814 / 8.702681"

pushd src &>/dev/null

./setup.sh "$@"

popd &>/dev/null
