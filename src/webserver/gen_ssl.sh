#!/bin/bash

# requires:
# sudo apt install openssl

if [ ! -d /dev/shm/cert ]; then
  mkdir -p /dev/shm/cert
fi
cd /dev/shm/cert
if [ ! -f rpi_scanner.crt ] || [ ! -f rpi_scanner.key ]; then
  rm rpi_scanner.crt rpi_scanner.key
  openssl req -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out rpi_scanner.crt  -keyout rpi_scanner.key -subj "/C=DE/ST=mobile/L=unknown/O=FMLIST.org/OU=FMLIST_Scanner/CN=fmlist.org/emailAddress=fmlist-scanner@groups.io"
fi
