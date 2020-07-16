#!/bin/bash

if [ -z "$1" ]; then
  echo "usage: $0 [print] [<BINDIR>]"
  echo "  default BINDIR is ../../bin"
  #echo "  default BINDIR is \$HOME/bin"
  echo ""
fi

if [ "$1" == "print" ]; then
  OPTPRINT="1"
  shift
else
  OPTPRINT=""
fi


#BINDIR="$HOME/bin"
BINDIR="../../bin"
if [ ! -z "$1" ]; then
  BINDIR="$1"
fi

CONFDIR="$HOME/.config/fmlist_scan"

DIFF="$(which colordiff)"
if [ -z "${DIFF}" ]; then
  DIFF="$(which diff)"
fi


for f in $( ls -1 *.sh *.py scanner/*.sh scanner/*.py webserver/*.py ) ; do
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
      echo -e "diff $f\t\tequal"
    else
      echo -e "diff $f\t\tNOT equal\t\tmeld ${BINDIR}/$b $f"
      if [ "${OPTPRINT}" = "1" ]; then
        ${DIFF} "$f" "${BINDIR}/$b"
        echo ""
      fi
    fi
  else
    echo "$b not in ${BINDIR}"
  fi
done

for f in $( ls -1 "${BINDIR}" ) ; do
  if [ ! -f "$f" ] && [ ! -f "scanner/$f" ] && [ ! -f "webserver/$f" ]; then
    echo "file $f exists in ${BINDIR} but neither in . nor in scanner nor in webserver"
  fi
done

for f in $( echo "config fmscan.inc dabscan.inc dab_chanlist.txt local_GPS_COORDS.inc local_SUN_TIMES.inc local_FM_stations.csv local_DAB_stations.csv" ) ; do
  b=$( basename "$f" )

  if [ -f "${CONFDIR}/$b" ]; then
    ND=$( diff conf/$f "${CONFDIR}/$b" | wc -l )
    if [ $ND -eq 0 ]; then
      echo -e "diff conf/$f\t\tequal"
    else
      echo -e "diff conf/$f\t\tNOT equal\t\tmeld ${CONFDIR}/$b conf/$f"
      if [ "${OPTPRINT}" = "1" ]; then
        ${DIFF} "conf/$f" "${CONFDIR}/$b"
        echo ""
      fi
    fi
  else
    echo "$b not in ${CONFDIR}"
  fi
done


crontab -l >crontab.user

cp /lib/systemd/system/gpio-input.service pishutdown/gpio-input.service.sys
cp /etc/default/gpsd gpsd.conf.sys
