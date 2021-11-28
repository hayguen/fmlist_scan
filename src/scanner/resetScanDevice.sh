#!/bin/bash

source "$HOME/.config/fmlist_scan/config"
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

type="$1"
SLEEPDUR="5"

if [ "${type}" = "all" ]; then
  echo "check number of Realtek devices .."
  NUMDEV=$(rtl_test 2>&1 |grep Realtek |wc -l)
  echo "found ${NUMDEV} Realtek devices"
  for N in $(seq 1 $NUMDEV) ; do
    echo "determine serial for device no $N .."
    SN=$(rtl_test 2>&1 |grep Realtek |head -n $N |nl |tail -n 1 |sed "s/^\s*${N}\s*/MATCHED_RTL/g" |grep "^MATCHED_RTL" |sed 's/.*SN: //g')
    if [ -z "${SN}" ]; then
      echo "Error: cannot determine serial for device no $N"
      exit 0
    fi
    if [ "$2" = "power" ]; then
      echo "powering off device $N with serial ${SN}"
      powerOff_rtl_by_serial.sh scan_dev_${N} "${SN}"
      echo "sleep ${SLEEPDUR} secs after powering off"
      sleep ${SLEEPDUR}
      echo "powering on  device $N with serial ${SN}"
      powerOn_rtl_by_serial.sh scan_dev_${N}
      echo "powering finished"
    fi
    echo "resetting USB device $N with serial ${SN}"
    reset_rtl_by_serial.sh "${SN}"
    echo "sleep ${SLEEPDUR} secs after reset"
    sleep ${SLEEPDUR}
  done
  echo "finished"
  exit 0

elif [ "${type}" = "fm" ]; then
  SN="${FMLIST_FM_RTLSDR_DEV}"
  if [ -z "${SN}" ]; then
    echo "reset requires config entry 'FMLIST_FM_RTLSDR_DEV' with the serial number of the device!"
    exit 10
  fi
  if [ "$2" = "power" ]; then
    echo "powering off FM device with serial ${SN}"
    powerOff_rtl_by_serial.sh scanFM "${SN}"
    echo "sleep ${SLEEPDUR} secs after powering off"
    sleep ${SLEEPDUR}
    echo "powering on  FM device with serial ${SN}"
    powerOn_rtl_by_serial.sh scanFM
    echo "powering finished"
  fi
  echo "resetting USB device for FM with serial ${SN}"
  reset_rtl_by_serial.sh "${SN}"
  echo "sleep ${SLEEPDUR} secs after reset"
  sleep ${SLEEPDUR}
  exit 0

elif [ "${type}" = "dab" ]; then
  SN="${FMLIST_DAB_RTLSDR_DEV}"
  if [ -z "${SN}" ]; then
    echo "reset requires config entry 'FMLIST_DAB_RTLSDR_DEV' with the serial number of the device!"
    exit 10
  fi
  if [ "$2" = "power" ]; then
    echo "powering off DAB device with serial ${SN}"
    powerOff_rtl_by_serial.sh scanDAB "${SN}"
    echo "sleep ${SLEEPDUR} secs after powering off"
    sleep ${SLEEPDUR}
    echo "powering on  DAB device with serial ${SN}"
    powerOn_rtl_by_serial.sh scanDAB
    echo "powering finished"
  fi
  echo "resetting USB device for DAB with serial ${SN}"
  reset_rtl_by_serial.sh "${SN}"
  echo "sleep ${SLEEPDUR} secs after reset"
  sleep ${SLEEPDUR}
  exit 0

else
  echo "usage: $0 fm|dab|all"
  exit 10
fi

