#!/bin/bash

searchedSerial="$1"

pushd /sys/bus/usb/drivers/usb &>/dev/null


for d in $( ls -1 ) ; do
  if [[ -L "$d" && -d "$d" ]]; then
    p="$(cat "$d/product" 2>/dev/null)"
    s="$(cat "$d/serial" 2>/dev/null)"
    if [ ! -z "$p" ]; then
      if [ -z "$searchedSerial" ]; then
        echo -n  "$(cat "$d/idVendor"):$(cat "$d/idProduct")"
        echo -en "\t"
        echo -n  "usbid '$d'"
        echo -en "\t"
        echo -n  "product '$p'"
        echo -en "\t"
        echo -n  "serial '$s'"
        echo ""
      elif [ "$searchedSerial" = "$s" ]; then
        echo "$d"
        exit 0
      fi
    fi
  fi
done

popd &>/dev/null

