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
gpio mode 27 output		# init external green LED
gpio mode 26 output		# init external red LED
gpio write 27 off	# green OFF
gpio write 26 off	# red OFF

