#!/bin/bash

export LC_ALL=C
source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

# start gps in background?
$HOME/bin/startGpsLoop.sh

if [ -f $HOME/.config/fmlist_scan/fmscan.inc ]; then
  cp $HOME/.config/fmlist_scan/fmscan.inc ${FMLIST_SCAN_RAM_DIR}/
fi

if [ -f $HOME/.config/fmlist_scan/dabscan.inc ]; then
  cp $HOME/.config/fmlist_scan/dabscan.inc ${FMLIST_SCAN_RAM_DIR}/
fi

if [ -f $HOME/.config/fmlist_scan/dab_chanlist.txt ]; then
  cp $HOME/.config/fmlist_scan/dab_chanlist.txt ${FMLIST_SCAN_RAM_DIR}/
fi

N=0
NUM_RTL_FAILS=0

cd ${FMLIST_SCAN_RAM_DIR}

if [ $( echo "$PATH" | grep -c "/usr/local/bin" ) -eq 0 ]; then
  export PATH=/usr/local/bin:$PATH
fi

if [ $( echo "$PATH" | grep -c "$HOME/bin" ) -eq 0 ]; then
  export PATH="$HOME/bin:$PATH"
fi

if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
  sudo -E $HOME/bin/rpi3b_led_init.sh
fi

if [ -f "${FMLIST_SCAN_RAM_DIR}/stopScanLoop" ]; then
  rm "${FMLIST_SCAN_RAM_DIR}/stopScanLoop"
fi

if [ -f "${FMLIST_SCAN_RAM_DIR}/abortScanLoop" ]; then
  rm "${FMLIST_SCAN_RAM_DIR}/abortScanLoop"
fi

#

echo -e "\\nSTARTING_SCANNER\\n\\n" >>${FMLIST_SCAN_RAM_DIR}/scanner.log


echo -e "\\nhostnamectl" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
hostnamectl >>${FMLIST_SCAN_RAM_DIR}/scanner.log
echo "" >>${FMLIST_SCAN_RAM_DIR}/scanner.log


echo -e "\\n/etc/os-release:" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
cat /etc/os-release >>${FMLIST_SCAN_RAM_DIR}/scanner.log
echo "" >>${FMLIST_SCAN_RAM_DIR}/scanner.log

echo -e "\\nlsb_release -a:" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
lsb_release -a >>${FMLIST_SCAN_RAM_DIR}/scanner.log
echo "" >>${FMLIST_SCAN_RAM_DIR}/scanner.log

if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
  echo -e "\\nvcgencmd version:" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  vcgencmd version >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  echo "" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
fi

echo -e "\\n/proc/cpuinfo:" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
cat /proc/cpuinfo >>${FMLIST_SCAN_RAM_DIR}/scanner.log
echo "" >>${FMLIST_SCAN_RAM_DIR}/scanner.log

NUMCPUS=$(cat /proc/cpuinfo | grep ^processor | wc -l)
echo -e "\\nNUMCPUS=${NUMCPUS}\\n" >>${FMLIST_SCAN_RAM_DIR}/scanner.log

if [ ${FMLIST_SCAN_SAVE_PWMTONE} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
  sleep 1
  scanToneFeedback.sh welcome
fi

# temperature - human readable: $(vcgencmd measure_temp)
# temperature in /1000 degree:  $(cat /sys/class/thermal/thermal_zone0/temp)
# echo -e "\\nTemperature: $(cat /sys/class/thermal/thermal_zone0/temp)\\n" >>${FMLIST_SCAN_RAM_DIR}/scanner.log

while /bin/true; do

  if [ -f "${FMLIST_SCAN_RAM_DIR}/stopScanLoop" ]; then
    break
  fi

  N=$[ $N + 1 ]
  echo "scanloop iteration $N"

  # test RTL dongle for FM
  TESTED_FIRST_DEV="0"
  TESTED_FM_DEV="0"
  if [ "${FMLIST_SCAN_FM}" != "0" ] && [ "${FMLIST_SCAN_FM}" != "OFF" ]; then
    echo "test rtl_sdr for FM ${FMLIST_FM_RTLSDR_DEV}"
    echo "test rtl_sdr for FM ${FMLIST_FM_RTLSDR_DEV}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    if [ -z "${FMLIST_FM_RTLSDR_DEV}" ]; then
      FMLIST_FM_RTLSDR_OPT=""
      TESTED_FIRST_DEV="1"
    else
      FMLIST_FM_RTLSDR_OPT="-d ${FMLIST_FM_RTLSDR_DEV}"
    fi
    TESTED_FM_DEV="1"
    rtl_sdr -f 100M -n 512 ${FMLIST_FM_RTLSDR_OPT} ${FMLIST_SCAN_RAM_DIR}/test.raw &>>${FMLIST_SCAN_RAM_DIR}/scanner.log
    if [ $? -ne 0 ]; then
      echo "error at test rtl_sdr! for FM"
      echo "error at test rtl_sdr! for FM" &>>${FMLIST_SCAN_RAM_DIR}/scanner.log
      if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
        sudo -E $HOME/bin/rpi3b_led_blinkRed.sh
        scanToneFeedback.sh error
      fi
      NUM_RTL_FAILS=$[ ${NUM_RTL_FAILS} + 1 ]
      if [ ${NUM_RTL_FAILS} -eq ${FMLIST_SCAN_DEAD_RTL_TRIES} ] && [ ${FMLIST_SCAN_DEAD_REBOOT} -ne 0 ]; then
        DTF="$(date -u "+%Y-%m-%dT%T.%N Z")"
        echo "going for reboot after FMLIST_SCAN_DEAD_RTL_TRIES = ${FMLIST_SCAN_DEAD_RTL_TRIES}. reboot is activated in $HOME/.config/fmlist_scan/config"
        echo "${DTF}: scanLoop.sh: saving results, then rebooting .." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
        if [ "${FMLIST_SCAN_SAVE_PARTIAL}" = "1" ]; then
          saveScanResults.sh savelog
        else
          rmScanResults.sh
        fi
        echo "${DTF}: going for reboot after FMLIST_SCAN_DEAD_RTL_TRIES = ${FMLIST_SCAN_DEAD_RTL_TRIES} .." >>"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/reboots.log"
        sudo reboot now
        exit 0
      fi
      echo "retry ${NUM_RTL_FAILS} of test - because rtl_sdr test for FM failed!"
      continue
    fi
  fi

  if [ "${FMLIST_SCAN_DAB}" != "0" ] && [ "${FMLIST_SCAN_DAB}" != "OFF" ]; then
  if [ -z "${FMLIST_DAB_RTLSDR_DEV}" ] && [ "${TESTED_FIRST_DEV}" = "1" ]; then
    echo "skiping test rtl_sdr for DAB: it's same default device"
  elif [ ${TESTED_FM_DEV} = "1" ] && [ "${FMLIST_FM_RTLSDR_DEV}" = "${FMLIST_DAB_RTLSDR_DEV}" ]; then
    echo "skiping test rtl_sdr for DAB: it's same device as for FM"
  else
    # test 2nd RTL dongle for DAB
    echo "test rtl_sdr for DAB ${FMLIST_DAB_RTLSDR_DEV}"
    echo "test rtl_sdr for DAB ${FMLIST_DAB_RTLSDR_DEV}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    if [ -z "${FMLIST_DAB_RTLSDR_DEV}" ]; then
      FMLIST_DAB_RTLSDR_OPT=""
    else
      FMLIST_DAB_RTLSDR_OPT="-d ${FMLIST_DAB_RTLSDR_DEV}"
    fi
    rtl_sdr -f 100M -n 512 ${FMLIST_DAB_RTLSDR_OPT} ${FMLIST_SCAN_RAM_DIR}/test.raw &>>${FMLIST_SCAN_RAM_DIR}/scanner.log
    if [ $? -ne 0 ]; then
      echo "error at test rtl_sdr! for DAB"
      echo "error at test rtl_sdr! for DAB" &>>${FMLIST_SCAN_RAM_DIR}/scanner.log
      if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
        sudo -E $HOME/bin/rpi3b_led_blinkRed.sh
        scanToneFeedback.sh error
      fi
      NUM_RTL_FAILS=$[ ${NUM_RTL_FAILS} + 1 ]
      if [ ${NUM_RTL_FAILS} -eq ${FMLIST_SCAN_DEAD_RTL_TRIES} ] && [ ${FMLIST_SCAN_DEAD_REBOOT} -ne 0 ]; then
        DTF="$(date -u "+%Y-%m-%dT%T.%N Z")"
        echo "going for reboot after FMLIST_SCAN_DEAD_RTL_TRIES = ${FMLIST_SCAN_DEAD_RTL_TRIES}. reboot is activated in $HOME/.config/fmlist_scan/config"
        echo "${DTF}: scanLoop.sh: saving results, then rebooting .." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
        if [ "${FMLIST_SCAN_SAVE_PARTIAL}" = "1" ]; then
          saveScanResults.sh savelog
        else
          rmScanResults.sh
        fi
        echo "${DTF}: going for reboot after FMLIST_SCAN_DEAD_RTL_TRIES = ${FMLIST_SCAN_DEAD_RTL_TRIES} .." >>"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/reboots.log"
        sudo reboot now
        exit 0
      fi
      echo "retry ${NUM_RTL_FAILS} of test - because rtl_sdr test for DAB failed!"
      continue
    fi
  fi
  fi

  NUM_RTL_FAILS=0

  scanFM.sh
  if [ -f "${FMLIST_SCAN_RAM_DIR}/stopScanLoop" ]; then
    break
  fi

  scanDAB.sh
  if [ -f "${FMLIST_SCAN_RAM_DIR}/stopScanLoop" ]; then
    break
  fi

  if [ "$1" = "single" ] || [ "$1" = "singleshot" ]; then
    # stop loop before saving results. results are saved anyway after loop
    break
  fi

  # always save log .. to have it saved - especially when mobile
  echo -e "\\n*********** saveScanResults.sh ${FMLIST_SCAN_SAVE_LOG_OPT} \\n" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  saveScanResults.sh ${FMLIST_SCAN_SAVE_LOG_OPT}

  if [ ${FMLIST_SCAN_SAVE_PWMTONE} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
    if [ ${FMLIST_SCAN_PWM_FEEDBACK} -ne 0 ]; then
      sleep 0.5
    fi
    scanToneFeedback.sh saved
  fi
  if [ ${FMLIST_SCAN_SAVE_LEDPLAY} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
    sudo -E $HOME/bin/rpi3b_led_blinkRed.sh
  fi

done

if [ ! -f "${FMLIST_SCAN_RAM_DIR}/abortScanLoop" ]; then
  if [ "${FMLIST_SCAN_SAVE_PARTIAL}" = "1" ]; then
    echo -e "\\nend of scanLoop. calling saveScanResults.sh savelog .." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    saveScanResults.sh savelog
  else
    rmScanResults.sh
  fi
else
  rmScanResults.sh
fi

if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
  sudo -E $HOME/bin/rpi3b_led_init.sh
fi
if [ ${FMLIST_SCAN_SAVE_PWMTONE} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
  sleep 1
  scanToneFeedback.sh final
fi

if [ ! "${FMLIST_SCAN_GPS_ALL_TIME}" = "1" ]; then
  stopGpsLoop.sh silent
fi
