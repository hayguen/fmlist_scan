#!/bin/bash

if [ -z "$1" ]; then
  echo "usage: $0 <id_for_restore>"
  exit 0
fi

usbid="$(cat /dev/shm/rtl_usbid_$1)"
if [ -z "$usbid" ]; then
  echo "error: could not find usbid from id '$1'"
  exit 10
fi

echo "$usbid" |sudo tee /sys/bus/usb/drivers/usb/bind
