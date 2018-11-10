#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "usage: $0 <id_for_restore> <rtl_serial>"
  exit 0
fi

usbid="$( listUSBdevices.sh "$2" )"
if [ -z "$usbid" ]; then
  echo "error: could not find usbid for serial '$2'"
  exit 10
fi

echo -n "$usbid" >/dev/shm/rtl_usbid_$1
echo "$usbid" |sudo tee /sys/bus/usb/drivers/usb/unbind
