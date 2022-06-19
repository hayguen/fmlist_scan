#!/bin/bash

if [ -z "${FMLIST_SCAN_RAM_DIR}" ]; then
  source $HOME/.config/fmlist_scan/config
  if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
    mkdir -p "${FMLIST_SCAN_RAM_DIR}"
  fi
fi

export LC_ALL=C
cd "${FMLIST_SCAN_RAM_DIR}"

  cat gpscoor.log
  if [ -d /sys/class/thermal/thermal_zone0 ]; then
    #CPUTEMPS=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sed -e 's/\([0-9][0-9][0-9]\)$/.\1/g' | tr '\n' ' ')
    CPUTEMPS=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sed -e 's/\([0-9]\)\([0-9][0-9]\)$/.\1/g' | tr '\n' ' ')
    #CPUFREQS=$(cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_cur_freq 2>/dev/null | sed -e 's/\([0-9][0-9][0-9]\)$/.\1/g' | tr '\n' ' ')
    CPUFREQS=$(cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_cur_freq 2>/dev/null | sed -e 's/\([0-9][0-9][0-9]\)$//g' | tr '\n' ' ')
    CPUSTATUS=""
    if [ ! -z "${CPUTEMPS}" ]; then
      CPUSTATUS="Temperature: ${CPUTEMPS}deg"
    fi
    if [ ! -z "${CPUFREQS}" ]; then
      CPUSTATUS="${CPUSTATUS}  CPU Freq(s): ${CPUFREQS}MHz"
    fi
    echo "${CPUSTATUS}"
  fi
  if [ -f LAST ]; then
    echo -en "\nLast found station: "
    sed -e 's/0000$//g' -e 's/\([0-9][0-9]\)$/.\1 MHz/g' LAST

    CURR="$(date -u +%s)"
    LAST="$(stat -c %Y ${FMLIST_SCAN_RAM_DIR}/LAST)"
    D=$[ $CURR - $LAST ]
    echo "Delta from LAST to CURR = $D secs"
  else
    echo "Scanner should not run. No Last found station."
  fi
  echo "Scanner scanLoop is$( screen -ls |grep -c 'scanLoopBg' | sed 's/^0$/ NOT/g' |sed 's/^1$//g' ) running in screen."
  echo ""
  tail -n 10 checkBgScanLoop.log | grep -v "Delta from LAST to CURR"

  echo ""
  ( echo "unique, #DAB Ens., #DAB prg, #FM prg" ; SKIP_SCANNED=1 SKIP_MISSING=1 SKIP_ADD=1 scanEvalSummary.sh | awk -F, '{ OFS=","; print $1, $3, $5, $7; }' ) \
    | sed 's/^40,/scanned,/g' |sed 's/^41,/missed,/g' |sed 's/^42,/additional,/g' |sed 's/^43,/refs,/g' \
    | column -s , -t
