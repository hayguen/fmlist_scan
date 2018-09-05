#!/bin/bash

#export FMLIST_SCAN_USER="hayguen"   # default: automatically from $HOME/.config/fmlist_scan/config

pushd src &>/dev/null

./uninstall.sh "$@"

popd &>/dev/null
