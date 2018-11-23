#!/bin/bash

if [ -z "$1" ]; then
  echo "usage: $0 [print] [<BINDIR>]"
  echo "  default BINDIR is ../../bin"
  #echo "  default BINDIR is \$HOME/bin"
  echo ""
fi

#BINDIR="$HOME/bin"
BINDIR="../../bin"
if [ ! -z "$2" ]; then
  BINDIR="$2"
fi

DIFF="$(which colordiff)"
if [ -z "${DIFF}" ]; then
  DIFF="$(which diff)"
fi


for f in `ls -1 *.sh scanner/*.sh` ; do
  b=$( basename "$f" )

  if [ "$b" == "all.sh" ]; then
    continue
  fi
  if [ "$b" == "diff.sh" ]; then
    continue
  fi

  if [ -f "${BINDIR}/$b" ]; then
    ND=$( diff $f "${BINDIR}/$b" | wc -l )
    if [ $ND -eq 0 ]; then
      echo -e "diff $f:\t\tequal"
    else
      echo -e "diff $f:\t\tNOT equal"
      if [ "$1" == "print" ]; then
        ${DIFF} "$f" "${BINDIR}/$b"
        echo ""
      fi
    fi
  else
    echo "$b not in ${BINDIR}"
  fi
done

# simplify diff with current settings

CONFDIR="${BINDIR}/../.config/fmlist_scan"
cat "${CONFDIR}/config"            >setup_config.user
echo ""                           >>setup_config.user
cat "${CONFDIR}/fmscan.inc"       >>setup_config.user
echo ""                           >>setup_config.user
cat "${CONFDIR}/dabscan.inc"      >>setup_config.user
echo ""                           >>setup_config.user
cat "${CONFDIR}/dab_chanlist.txt" >>setup_config.user

crontab -l >crontab.user

cp /lib/systemd/system/gpio-input.service pishutdown/gpio-input.service.sys
cp /etc/default/gpsd gpsd.conf.sys
