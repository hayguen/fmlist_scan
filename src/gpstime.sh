#!/bin/bash

source $HOME/.config/fmlist_scan/config

# http://blog.petrilopia.net/linux/raspberry-pi-set-time-gps-dongle/

# ${FMLIST_SCAN_GPS_COORDS} : "static", "gps", "auto"
#   auto: try gpsd -> if not available, then use static coordinates

cd $HOME/ram
SYSTIM="$( date -u "+%Y-%m-%dT%T.%NZ" )"
SET_SYSTIM="0"
SET_STATIC="0"
SET_NONE="0"
if [ "${FMLIST_SCAN_GPS_COORDS}" = "static" ]; then
  SET_STATIC="1"
fi

#gpspipe -w | head -n 5 | grep TPV | egrep '("mode":2,|"mode":3)' | head -n 1 >gpsline.log
while true ; do
  if [ "${FMLIST_SCAN_GPS_COORDS}" = "auto" ] || [ "${FMLIST_SCAN_GPS_COORDS}" = "gps" ]; then
    rm -f gpslines.log
    timeout -s SIGKILL -k 5 3 bash -c "gpspipe -w |head -n 5" >gpslines.log
    NL="$( cat gpslines.log | wc -l )"
    #echo "gpslines has $NL lines"
    if [ $NL -le 1 ]; then
      echo "gpspipe did not return any results!"
      echo "GPS device not connected?"
      if [ "${FMLIST_SCAN_GPS_COORDS}" = "auto" ]; then
        SET_STATIC="1"
      fi
      break
    fi
    MdThree="$( grep TPV gpslines.log | grep -c '"mode":3,' )"
    MdTwo="$( grep TPV gpslines.log | grep -c '"mode":2,' )"
    if [ $MdThree -ne 0 ]; then
      GPSMODE="3"
      GPSSRC="gps"
      grep TPV gpslines.log | grep '"mode":3,' >gpsline.log
    elif [ $MdTwo -ne 0 ]; then
      GPSMODE="2"
      GPSSRC="gps"
      grep TPV gpslines.log | grep '"mode":2,' >gpsline.log
    else
      echo "GPS not synced to mode 2 or 3!"
      SET_NONE="1"
      break
    fi
    SET_SYSTIM="1"
    GPSTIM="$( sed -r 's/.*"time":"([^"]*)".*/\1/' gpsline.log )"
    GPSLAT="$( sed -r 's/.*"lat":([0-9.]*).*/\1/'  gpsline.log )"
    GPSLON="$( sed -r 's/.*"lon":([0-9.]*).*/\1/'  gpsline.log )"
    if [ $MdThree -ne 0 ]; then
      GPSALT="$( sed -r 's/.*"alt":([0-9.]*).*/\1/'  gpsline.log )"
    else
      GPSALT="-"
    fi
  fi
  break
done

if [ ${SET_STATIC} -eq 1 ]; then
  GPSTIM="${SYSTIM}"
  GPSMODE="0"
  GPSSRC="static"
  # static coordinates from config
  GPSLAT="${FMLIST_SCAN_GPS_LAT}"
  GPSLON="${FMLIST_SCAN_GPS_LON}"
  GPSALT="${FMLIST_SCAN_GPS_ALT}"
elif [ ${SET_NONE} -eq 1 ]; then
  GPSTIM="${SYSTIM}"
  GPSMODE="0"
  GPSSRC="none"
  # north pole
  GPSLAT="90.0"
  GPSLON="0.0"
  GPSALT="0"
fi

if [ ! -z "${GPSTIM}" ] && [ ! -z "${GPSLAT}" ] && [ ! -z "${GPSLON}" ]; then
  #echo "time with coordinates B: ${GPSLAT} / ${GPSLON} @ ${GPSTIM}"
  ( flock -x 213
    echo "${GPSLAT} / ${GPSLON} / ${GPSALT} @ gpstime ${GPSTIM} / systime ${SYSTIM} / mode ${GPSMODE} ${GPSSRC}"
    echo "${GPSLAT} / ${GPSLON} / ${GPSALT} @ gpstime ${GPSTIM} / systime ${SYSTIM} / mode ${GPSMODE} ${GPSSRC}" >gpscoor.log
    echo "SYSTIM=\"${SYSTIM}\""    >gpscoor.inc
    echo "GPSSRC=\"${GPSSRC}\""   >>gpscoor.inc
    echo "GPSTIM=\"${GPSTIM}\""   >>gpscoor.inc
    echo "GPSLAT=\"${GPSLAT}\""   >>gpscoor.inc
    echo "GPSLON=\"${GPSLON}\""   >>gpscoor.inc
    echo "GPSMODE=\"${GPSMODE}\"" >>gpscoor.inc
    echo "GPSALT=\"${GPSALT}\""   >>gpscoor.inc
    echo "${GPSLAT},${GPSLON},${GPSALT},${GPSTIM},${SYSTIM}" >>gpscoor.csv
  ) 213>gps.lock

  if [ ${SET_SYSTIM} -eq 1 ]; then
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
else
  echo "No GPS coordinates!"
fi

