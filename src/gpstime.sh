#!/bin/bash

source $HOME/.config/fmlist_scan/config

# http://blog.petrilopia.net/linux/raspberry-pi-set-time-gps-dongle/

cd $HOME/ram
if [ ! -z "${FMLIST_SCAN_GPS_COORDS}" ]; then
  ( flock -x 213
    echo "${FMLIST_SCAN_GPS_COORDS} @ $(date -u "+%Y-%m-%dT%T.%NZ")" >gpscoor.log
  ) 213>gps.lock
  exit 0
fi

#gpspipe -w | head -n 5 | grep TPV | egrep '("mode":2,|"mode":3)' | head -n 1 >gpsline.log

rm -f gpslines.log
timeout -s SIGKILL -k 5 3 bash -c "gpspipe -w |head -n 5" >gpslines.log

NL=$( cat gpslines.log | wc -l  )
echo "gpslines hat $NL lines"
if [ $NL -le 1 ]; then
  echo "gpspipe did not return any results!"
  echo "GPS device not connected?"
  exit 10
fi

MdThree=$( grep TPV gpslines.log | grep -c '"mode":3,' )
MdTwo=$( grep TPV gpslines.log | grep -c '"mode":2,' )

if [ $MdThree -ne 0 ]; then
  GPSMODE="3"
  grep TPV gpslines.log | grep '"mode":3,' >gpsline.log
elif [ $MdTwo -ne 0 ]; then
  GPSMODE="2"
  grep TPV gpslines.log | grep '"mode":2,' >gpsline.log
else
  echo "GPS not synced to mode 2 or 3!"
  exit 10
fi

#cat gpsline.log | sed -r 's/.*"lat":([^,]*).*/\1/'
SYSTIM="$( date -u "+%Y-%m-%dT%T.%NZ" )"
GPSTIM="$( sed -r 's/.*"time":"([^"]*)".*/\1/' gpsline.log )"
GPSLAT="$( sed -r 's/.*"lat":([0-9.]*).*/\1/'  gpsline.log )"
GPSLON="$( sed -r 's/.*"lon":([0-9.]*).*/\1/'  gpsline.log )"

if [ $MdThree -ne 0 ]; then
  GPSALT="$( sed -r 's/.*"alt":([0-9.]*).*/\1/'  gpsline.log )"
else
  GPSALT="-"
fi

if [ ! -z "${GPSTIM}" ] && [ ! -z "${GPSLAT}" ] && [ ! -z "${GPSLON}" ]; then
  #echo "time with coordinates B: ${GPSLAT} / ${GPSLON} @ ${GPSTIM}"
  ( flock -x 213
    echo "${GPSLAT} / ${GPSLON} / ${GPSALT} @ gpstime ${GPSTIM} / systime ${SYSTIM}"
    echo "${GPSLAT} / ${GPSLON} / ${GPSALT} @ gpstime ${GPSTIM} / systime ${SYSTIM}" >gpscoor.log
    echo "SYSTIM=\"${SYSTIM}\""    >gpscoor.inc
    echo "GPSTIM=\"${GPSTIM}\""   >>gpscoor.inc
    echo "GPSLAT=\"${GPSLAT}\""   >>gpscoor.inc
    echo "GPSLON=\"${GPSLON}\""   >>gpscoor.inc
    echo "GPSMODE=\"${GPSMODE}\"" >>gpscoor.inc
    echo "GPSALT=\"${GPSALT}\""   >>gpscoor.inc
  ) 213>gps.lock

  SYST=$(date -d "${SYSTIM}" -u +%s)
  GPST=$(date -d "${GPSTIM}" -u +%s)
  DELTA=$[ $GPST - $SYST ]

  echo "Delta from system to GPS time is $DELTA sec"
  if [ $DELTA -lt -3 ] || [ $DELTA -gt 3 ]; then
    echo "Setting system time."
    sudo date -u -s "${GPSTIM}"
  else
    echo "Not setting system time."
  fi

fi

