#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

# usage: gpstime.sh [single]
#   single:  single pass, then exit
# activate debug output setting environment variable GPSDBG=1
if [ "$1" = "single" ]; then
  if [ -f "${FMLIST_SCAN_RAM_DIR}/stopGps" ]; then
    rm "${FMLIST_SCAN_RAM_DIR}/stopGps"
  fi
  if [ -f "${FMLIST_SCAN_RAM_DIR}/gpscoor.inc" ]; then
    rm "${FMLIST_SCAN_RAM_DIR}/gpscoor.inc"
  fi
fi
if [ ! "${FMLIST_SCAN_SETUP_GPS}" = "1" ]; then
  echo "error: gpsd not installed!"
  exit 10
fi

while [ ! -f "${FMLIST_SCAN_RAM_DIR}/stopGps" ]; do

  source $HOME/.config/fmlist_scan/config

  # http://blog.petrilopia.net/linux/raspberry-pi-set-time-gps-dongle/

  # ${FMLIST_SCAN_GPS_COORDS} : "static", "gps", "auto"
  #   auto: try gpsd -> if not available, then use static coordinates

  cd ${FMLIST_SCAN_RAM_DIR}
  SYSTIM="$( date -u "+%Y-%m-%dT%T.%NZ" )"
  SET_SYSTIM="0"
  SET_STATIC="0"
  SET_NONE="0"
  if [ "${FMLIST_SCAN_GPS_COORDS}" = "static" ]; then
    SET_STATIC="1"
  fi

  while true ; do
    if [ "${FMLIST_SCAN_GPS_COORDS}" = "auto" ] || [ "${FMLIST_SCAN_GPS_COORDS}" = "gps" ]; then
      rm -f gpsline.log
      timeout -s SIGTERM -k 1 4 bash -c "gpspipe -w -n 5 | head -n 6 | grep TPV | egrep '(\"mode\":2,|\"mode\":3,)' | tail -n 1 >gpsline.log"
      if [ ! -z "$GPSDBG" ]; then
        echo "filtered result of gpspipe -w -n 5:"
        cat gpsline.log
        echo ""
      fi
      NL="$( cat gpsline.log | wc -l )"
      if [ ! -z "$GPSDBG" ]; then
        echo "gpslines has ${NL} lines"
      fi
      if [ $NL -lt 1 ]; then
        echo "gpspipe did not return any results!"
        echo "GPS device not connected?"
        if [ "${FMLIST_SCAN_GPS_COORDS}" = "auto" ]; then
          SET_STATIC="1"
        fi
        break
      fi
      MdThree="$( grep -c '"mode":3,' gpsline.log )"
      MdTwo="$(   grep -c '"mode":2,' gpsline.log )"
      if [ $MdThree -ne 0 ]; then
        GPSMODE="3"
        GPSSRC="gps"
        if [ ! -z "$GPSDBG" ]; then
          echo "detected mode 3"
        fi
      elif [ $MdTwo -ne 0 ]; then
        GPSMODE="2"
        GPSSRC="gps"
        if [ ! -z "$GPSDBG" ]; then
          echo "detected mode 2"
        fi
      else
        echo "GPS not synced to mode 2 or 3!"
        SET_NONE="1"
        break
      fi
      SET_SYSTIM="1"
      GPSTIM="$( sed -r 's/.*"time":"([^"]*)".*/\1/'  gpsline.log )"
      GPSLAT="$( sed -r 's/.*"lat":([0-9.\-]*).*/\1/' gpsline.log )"
      GPSLON="$( sed -r 's/.*"lon":([0-9.\-]*).*/\1/' gpsline.log )"
      if [ ! -z "$GPSDBG" ]; then
        echo "parsed GPSTIM: '${GPSTIM}'"
        echo "parsed GPSLAT: '${GPSLAT}'"
        echo "parsed GPSLON: '${GPSLON}'"
      fi
      if [ $MdThree -ne 0 ]; then
        GPSALT="$( sed -r 's/.*"alt":([0-9.\-]*).*/\1/' gpsline.log )"
      else
        GPSALT="-"
      fi
      if [ ! -z "$GPSDBG" ]; then
        echo "parsed GPSALT: '${GPSALT}'"
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
    if [ ! -z "$GPSDBG" ]; then
      echo "setting static coordindates: SET_STATIC = ${SET_STATIC}"
    fi
    # try to restart gpsd
    sudo systemctl stop gpsd
    if [ $( grep -c "DEVICES=\"/dev/ttyACM0" /etc/default/gpsd ) -ne 0 ]; then
      sudo sed -i "/DEVICES=/d" /etc/default/gpsd
      sudo bash -c 'echo "DEVICES=\"/dev/ttyUSB0\"" >>/etc/default/gpsd'
    else # if [ $( grep -c "DEVICES=\"/dev/ttyUSB0" /etc/default/gpsd ) -ne 0 ]; then
      sudo sed -i "/DEVICES=/d" /etc/default/gpsd
      sudo bash -c 'echo "DEVICES=\"/dev/ttyACM0\"" >>/etc/default/gpsd'
    fi
    sudo systemctl start gpsd
    FMLIST_SCAN_GPS_LOOP_SLEEP="$[ ${FMLIST_SCAN_GPS_LOOP_SLEEP} + 3 ]"
  elif [ ${SET_NONE} -eq 1 ]; then
    GPSTIM="${SYSTIM}"
    GPSMODE="0"
    GPSSRC="none"
    # north pole
    GPSLAT="90.0"
    GPSLON="0.0"
    GPSALT="0"
  fi

  NL_GPS="$( echo -n "${GPSLAT} / ${GPSLON} / ${GPSALT} @ gpstime ${GPSTIM} / systime ${SYSTIM} / mode ${GPSMODE} ${GPSSRC}" | wc -l )"

  if [ ! -z "${GPSTIM}" ] && [ ! -z "${GPSLAT}" ] && [ ! -z "${GPSLON}" ] && [ "${NL_GPS}" = "0" ] && [ "${GPSSRC}" != "none" ]; then
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
      GPSFN="${GPSSRC}#${GPSMODE}#${GPSLAT}#${GPSLON}#${GPSALT}"
      echo "GPSFN=\"${GPSFN}\""     >>gpscoor.inc
      if [ ${GPSMODE} -ne 0 ]; then
        echo "${GPSLAT},${GPSLON},${GPSALT},${GPSTIM},${SYSTIM}" >>gpscoor.csv
      fi
    ) 213>${FMLIST_SCAN_RAM_DIR}/gps.lock

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
        if [ ! -z "$GPSDBG" ]; then
          echo "Not setting system time, cause delta to systemtime < 3 sec"
        fi
      fi
    fi
  else
    echo "No GPS coordinates!"
    echo "* ${NL_GPS}: ${GPSLAT} / ${GPSLON} / ${GPSALT} @ gpstime ${GPSTIM} / systime ${SYSTIM} / mode ${GPSMODE} ${GPSSRC}" >>gpsNL-Errs.log
    if [ ! -z "$GPSDBG" ]; then
      echo "  NL_GPS:  '${NL_GPS}' = '0'"
      echo "  GPSLAT:  '${GPSLAT}' != ''"
      echo "  GPSLON:  '${GPSLON}' != ''"
      echo "  GPSALT:  '${GPSALT}' != ''"
      echo "  GPSTIM:  '${GPSTIM}' != ''"
      echo "  GPSMODE: '${GPSMODE}'"
      echo "  GPSSRC:  '${GPSSRC}' != 'none'"
    fi
  fi

  if [ "$1" = "single" ]; then
    exit 0
  fi

  sleep ${FMLIST_SCAN_GPS_LOOP_SLEEP}

done

