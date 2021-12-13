#!/bin/bash

#export FMLIST_SCAN_USER="hayguen"  # default Linux OS user "pi" - with sudo rights
#export FMLIST_SCAN_RASPI="0"       # default "1" if Raspberry Pi hardware
#export FMLIST_SCAN_SETUP_GPS="1"   # default "1" to activate gpsd and cronjob for user. set to "1" also for PC

#export FMLIST_SCAN_MOUNT="0"       # default "1" to setup FMLIST_SCAN_RESULT_DEV in /etc/fstab. set "0" without USB memory stick
#export FMLIST_SCAN_RESULT_DEV="/dev/sda1"
#export FMLIST_SCAN_RESULT_DIR="/mnt/sda1"  # where to mount the device .. and access the contents
#export FMLIST_SCAN_RESULT_DIR="/home/fmlist/results"  # set this existing path, without USB memory stick

#export FMLIST_USER=""              # optional: username (email) at https://www.fmlist.org/
#export FMLIST_OM_ID=""             # optional: OM id at https://www.fmlist.org/

pushd src &>/dev/null

./setup.sh "$@"

popd &>/dev/null
