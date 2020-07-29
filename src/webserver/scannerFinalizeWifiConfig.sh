#!/bin/bash

FINALNAME="$1"
if [ -z "${FINALNAME}" ]; then
  FINALNAME="wpa_supplicant.conf"
fi
FINALPATH="/dev/shm/wpa_supplicant/${FINALNAME}"

sudo cp /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant_old_bak.conf
sudo install -m 660 -o root -g root "${FINALPATH}" /etc/wpa_supplicant/wpa_supplicant.conf
