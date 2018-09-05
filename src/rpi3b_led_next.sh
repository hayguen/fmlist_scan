#!/bin/bash

if [ -z "${FMLIST_SCAN_RASPI}" ]; then
  source $HOME/.config/fmlist_scan/config
fi
if [ ${FMLIST_SCAN_RASPI} -eq 0 ]; then
  exit 0
fi

CURR="$(date -u +%s)"

if [ -f $HOME/ram/STATE ]; then
  S="$(cat $HOME/ram/STATE)"
  LAST="$(stat -c %Y $HOME/ram/STATE)"
else
  S=0
  LAST=0
fi

if [ ! "$1" == "-it" ]; then
  D=$[ $CURR - $LAST ]
  if [ $D -le 1 ]; then
    exit 0
  fi
fi


# n: gr
# 0: +r ==> 01
# 1: +g ==> 11
# 2: -r ==> 10
# 3: -g ==> 00

if [ $S -eq 0 ]; then
  echo 0 > /sys/class/leds/led0/brightness
  echo 1 > /sys/class/leds/led1/brightness
elif [ $S -eq 1 ]; then
  echo 1 > /sys/class/leds/led0/brightness
  echo 1 > /sys/class/leds/led1/brightness
elif [ $S -eq 2 ]; then
  echo 1 > /sys/class/leds/led0/brightness
  echo 0 > /sys/class/leds/led1/brightness
elif [ $S -eq 3 ]; then
  echo 0 > /sys/class/leds/led0/brightness
  echo 0 > /sys/class/leds/led1/brightness
fi

S="$[ ($S + 1) % 2 ]"
echo -n "$S" >$HOME/ram/STATE

