#!/bin/bash

if [ -z "$1" ]; then
  echo "usage: $0 <rtl_serial>"
  exit 0
fi

busdev="$( listUSBdevices.sh "$1" "busdev")"
if [ -z "$busdev" ]; then
  echo "error: could not find bus/dev for serial '$1'. all devices:"
  listUSBdevices.sh
  exit 10
fi

echo "usbreset ${busdev}"
usbreset "$busdev"
