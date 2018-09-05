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

# n: gr
# 0: +r ==> 01
# 1: +g ==> 11
# 2: -r ==> 10
# 3: -g ==> 00

while /bin/true ; do
  sleep 0.5
  # 1: +g ==> 11
  echo 1 > /sys/class/leds/led0/brightness
  sleep 0.5
  # 2: -r ==> 10
  echo 0 > /sys/class/leds/led1/brightness
  sleep 0.5
  # 3: -g ==> 00
  echo 0 > /sys/class/leds/led0/brightness
  sleep 0.5
  # 0: +r ==> 01
  echo 1 > /sys/class/leds/led1/brightness
done

