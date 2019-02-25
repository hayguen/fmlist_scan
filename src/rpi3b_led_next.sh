#!/bin/bash

if [ -z "${FMLIST_SCAN_RASPI}" ]; then
  source $HOME/.config/fmlist_scan/config
fi
if [ ${FMLIST_SCAN_RASPI} -eq 0 ]; then
  exit 0
fi

CURR="$(date -u +%s)"

if [ -f ${FMLIST_SCAN_RAM_DIR}/STATE ]; then
  S="$(cat ${FMLIST_SCAN_RAM_DIR}/STATE)"
  LAST="$(stat -c %Y ${FMLIST_SCAN_RAM_DIR}/STATE)"
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
  # internal: green OFF  red ON
  # external: green OFF  red ON
  echo 0 > /sys/class/leds/led0/brightness	# internal green
  echo 1 > /sys/class/leds/led1/brightness	# internal red
  gpio write ${FMLIST_SCAN_WPI_LED_GREEN} off # external green
  gpio write ${FMLIST_SCAN_WPI_LED_RED} on    # external red
elif [ $S -eq 1 ]; then
  # internal: green ON  red ON
  # external: green ON  red ON
  echo 1 > /sys/class/leds/led0/brightness
  echo 1 > /sys/class/leds/led1/brightness
  gpio write ${FMLIST_SCAN_WPI_LED_GREEN} on
  gpio write ${FMLIST_SCAN_WPI_LED_RED} on
elif [ $S -eq 2 ]; then
  # internal: green ON  red OFF
  # external: green ON  red OFF
  echo 1 > /sys/class/leds/led0/brightness
  echo 0 > /sys/class/leds/led1/brightness
  gpio write ${FMLIST_SCAN_WPI_LED_GREEN} on
  gpio write ${FMLIST_SCAN_WPI_LED_RED} off
elif [ $S -eq 3 ]; then
  # internal: green OFF red OFF
  # external: green OFF red OFF
  echo 0 > /sys/class/leds/led0/brightness
  echo 0 > /sys/class/leds/led1/brightness
  gpio write ${FMLIST_SCAN_WPI_LED_GREEN} off
  gpio write ${FMLIST_SCAN_WPI_LED_RED} off
fi

S="$[ ($S + 1) % 4 ]"
echo -n "$S" >${FMLIST_SCAN_RAM_DIR}/STATE

