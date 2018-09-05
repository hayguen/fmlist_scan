#!/bin/bash

source $HOME/.config/fmlist_scan

# http://blog.petrilopia.net/linux/raspberry-pi-set-time-gps-dongle/


#GPSDATE=$(gpspipe -w | head -10 | grep TPV | sed -r 's/.*"time":"([^"]*)".*/\1/' | head -1)
#GPSDATE=$(gpspipe -w -n 10 | grep TPV | sed -r 's/.*"time":"([^"]*)".*/\1/' | tail -n 1 | sed -e 's/^\(.\{10\}\)T\(.\{8\}\).*/\1 \2/')

cd $HOME/ram
if [ ! -z "${FMLIST_SCAN_GPS_COORDS}" ]; then
  ( flock -x 213
    echo "${FMLIST_SCAN_GPS_COORDS} @ $(date -u "+%Y-%m-%dT%T.%NZ")" >gpscoor.log
  ) 213>gps.lock
  exit 0
fi

#gpspipe -w | head -n 5 | grep TPV | grep \"mode\":3, | head -n 1 >gpsline.log
gpspipe -w | head -n 5 | grep TPV | grep '"mode":3,' | head -n 1 >gpsline.log
#gpspipe -w | head -n 5 | grep TPV | egrep '("mode":2,|"mode":3)' | head -n 1 >gpsline.log

#cat gpsline.log | sed -r 's/.*"lat":([^,]*).*/\1/'
TIM=$( sed -r 's/.*"time":"([^"]*)".*/\1/' gpsline.log )
LAT=$( sed -r 's/.*"lat":([0-9.]*).*/\1/'  gpsline.log )
LON=$( sed -r 's/.*"lon":([0-9.]*).*/\1/'  gpsline.log )

#echo "time with coordinates A: ${LAT} / ${LON} @ ${TIM}"

if [ ! -z "$TIM" ] && [ ! -z "$LAT" ] && [ ! -z "$LON" ]; then
  #echo "time with coordinates B: ${LAT} / ${LON} @ ${TIM}"
  ( flock -x 213
    echo "time with coordinates: ${LAT} / ${LON} @ ${TIM}"
    echo "${LAT} / ${LON} @ ${TIM}" >gpscoor.log
  ) 213>gps.lock

  if [ -f prevSysTime ]; then
    PDT="$(cat prevSysTime)"
  else
    PDT="0"
  fi
  CDT=$(date -u +%s)
  if [ $CDT -lt 3600 ]; then
    echo "system time is not set"
    CDT=0
  fi
  echo "if [ $[ $PDT + 15*60 ] -lt $CDT ]; then .."
  if [ $[ $PDT + 15*60 ] -lt $CDT ]; then
    echo setting system time
    sudo date -u -s "$TIM"
    date -u +%s >prevSysTime
  else
    echo not setting system time
  fi

fi

