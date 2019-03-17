#!/bin/bash

if [ ! -f /etc/sidedoor/id_rsa_sidedoor ]; then
  >&2 echo "uploadScanFilesToDeveloper.sh requires following steps:"
  >&2 echo "sudo ln /etc/sidedoor/id_rsa /etc/sidedoor/id_rsa_sidedoor"
  >&2 echo "sudo chown pi:pi /etc/sidedoor/id_rsa_sidedoor"
  >&2 echo "sudo chmod 600 /etc/sidedoor/id_rsa_sidedoor"
  exit 10
fi

if [ ! "$(whoami)" = "$(stat --format '%U' /etc/sidedoor/id_rsa_sidedoor)" ]; then
  >&2 echo "uploadScanFilesToDeveloper.sh requires following steps:"
  >&2 echo "sudo chown pi:pi /etc/sidedoor/id_rsa_sidedoor"
  >&2 echo "sudo chmod 600 /etc/sidedoor/id_rsa_sidedoor"
  exit 10
fi

if [ ! "600" = "$(stat -c %a /etc/sidedoor/id_rsa_sidedoor)" ]; then
  >&2 echo "uploadScanFilesToDeveloper.sh requires following steps:"
  >&2 echo "sudo chmod 600 /etc/sidedoor/id_rsa_sidedoor"
  exit 10
fi

if [ ! "25a5fd0f639eae130432204ad1a2cdbf7d2bc6d5" = "$(sha1sum /etc/sidedoor/id_rsa_sidedoor | awk '{ print $1; }')" ]; then
  >&2 echo "uploadScanFilesToDeveloper.sh requires private/public key for upload@hayguen.hopto.org"
  >&2 echo "the keys are delivered with the prepared image. ask h_ayguen@web.de via email"
  exit 10
fi

if [ -z "$1" ] || [ -z "$2" ]; then
  >&2 echo "usage: $(basename "$0") <target_foldername> <files>+"
  exit 0
fi

DESTDIR="$1"
shift

ssh -p 22345 -i /etc/sidedoor/id_rsa_sidedoor upload@hayguen.hopto.org "mkdir /pub/${DESTDIR}"
scp -P 22345 -i /etc/sidedoor/id_rsa_sidedoor "$@" "upload@hayguen.hopto.org:pub/${DESTDIR}/"
