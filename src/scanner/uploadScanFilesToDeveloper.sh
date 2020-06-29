#!/bin/bash

if [ ! -f /etc/sidedoor/id_rsa_sidedoor ]; then
  >&2 echo "uploadScanFilesToDeveloper.sh requires following steps:"
  >&2 echo "sudo cp /etc/sidedoor/id_rsa /etc/sidedoor/id_rsa_sidedoor"
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

SS=$(sha1sum /etc/sidedoor/id_rsa_sidedoor | awk '{ print $1; }')
ESS="1e3afb7a6dfb83ce4c4229abe4a068a8fe393110"
if [ ! "${ESS}" = "${SS}" ]; then
  >&2 echo "warning: sha1sum of /etc/sidedoor/id_rsa_sidedoor is ${SS}. expected ${ESS}"
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
scp -P 22345 -i /etc/sidedoor/id_rsa_sidedoor -r "$@" "upload@hayguen.hopto.org:pub/${DESTDIR}/"
