#!/bin/bash

#export FMLIST_SCAN_USER="hayguen"  # default OS user "pi"
#export FMLIST_SCAN_RASPI="0"       # default "1" if Raspberry Pi hardware
#export FMLIST_SCAN_SETUP_GPS="0"   # default "1" to activate gpsd and cronjob for user
#export FMLIST_USER=""              # optional: username (email) at https://www.fmlist.org/
#export FMLIST_OM_ID=""             # optional: OM id at https://www.fmlist.org/

pushd src &>/dev/null

./setup.sh "$@"

popd &>/dev/null
