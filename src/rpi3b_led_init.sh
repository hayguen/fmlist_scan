#!/bin/bash

if [ -z "${FMLIST_SCAN_RASPI}" ]; then
  source $HOME/.config/fmlist_scan
fi
if [ ${FMLIST_SCAN_RASPI} -eq 0 ]; then
  exit 0
fi

# green
echo none > /sys/class/leds/led0/trigger
# red
echo none > /sys/class/leds/led1/trigger

sleep 0.1
# ./init.sh
echo 0 > /sys/class/leds/led0/brightness
echo 1 > /sys/class/leds/led1/brightness

