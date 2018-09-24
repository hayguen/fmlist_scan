#!/bin/bash

#export FMLIST_SCAN_USER="hayguen"   # default user "pi"
#export FMLIST_SCAN_RASPI="0"       # default "1" if Raspberry Pi hardware

pushd src &>/dev/null

./setup.sh "$@"

popd &>/dev/null
