#!/bin/bash

if [ -z "${FMLIST_SCAN_RASPI}" ]; then
  source $HOME/.config/fmlist_scan/config
fi
if [ ${FMLIST_SCAN_RASPI} -eq 0 ]; then
  exit 0
fi

# Rapberry Pi's onboard LEDs
echo none > /sys/class/leds/led0/trigger	# green
echo none > /sys/class/leds/led1/trigger	# red

sleep 0.1
echo 0 > /sys/class/leds/led0/brightness	# green OFF
echo 1 > /sys/class/leds/led1/brightness	# red ON

# external ATX LEDs
gpio mode ${FMLIST_SCAN_WPI_LED_GREEN} output # init external green LED (was 27)
gpio mode ${FMLIST_SCAN_WPI_LED_RED} output   # init external red LED
gpio write ${FMLIST_SCAN_WPI_LED_GREEN} off   # green OFF (was 27)
gpio write ${FMLIST_SCAN_WPI_LED_RED} off     # red OFF

