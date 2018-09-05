#!/bin/bash

if [ -z "${FMLIST_SCAN_RASPI}" ]; then
  source $HOME/.config/fmlist_scan/config
fi
if [ ${FMLIST_SCAN_RASPI} -eq 0 ]; then
  exit 0
fi

# 3 x ( black - red ) # show saving
for c in `echo 1 2 3` ; do
  # set black / off both leds
  echo -n "3" >$HOME/ram/STATE
  $HOME/bin/rpi3b_led_next.sh -it
  sleep 0.25

  # set red led on
  echo -n "0" >$HOME/ram/STATE
  $HOME/bin/rpi3b_led_next.sh -it
  sleep 0.25
done

