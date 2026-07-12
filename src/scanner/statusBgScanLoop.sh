#!/bin/bash

if [ -z "${FMLIST_SCAN_RAM_DIR}" ]; then
  source $HOME/.config/fmlist_scan/config
  if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
    mkdir -p "${FMLIST_SCAN_RAM_DIR}"
  fi
fi

export LC_ALL=C
cd "${FMLIST_SCAN_RAM_DIR}"

FM_FROM_RAM=""
DAB_FROM_RAM=""
LATEST_FM_DIR="$(ls -1dt scan_*_FM 2>/dev/null | head -n1)"
if [ ! -z "${LATEST_FM_DIR}" ]; then
  FM_FROM_RAM="$(awk -F',' '
    NF >= 3 {
      ts = $1 + 0
      freq = $3
      if (freq == "") next
      sub(/0000$/, "", freq)
      freq = substr(freq, 1, length(freq)-2) "." substr(freq, length(freq)-1)
      pi = (NF >= 13 ? $13 : "")
      ps = (NF >= 15 ? $15 : "")
      gsub(/"/, "", pi)
      gsub(/"/, "", ps)
      sub(/^0x/, "", pi)
      printf "%012d\t  FM %-10s", ts, freq " MHz"
      if (pi != "") printf " %s", pi
      if (ps != "") printf " %s", ps
      printf "\n"
    }
  ' "${LATEST_FM_DIR}"/fm_rds.*.csv 2>/dev/null | sort -n -k1,1 | cut -f2-)"
fi

LATEST_DAB_DIR="$(ls -1dt scan_*_DAB 2>/dev/null | head -n1)"
if [ ! -z "${LATEST_DAB_DIR}" ]; then
  DAB_FROM_RAM="$({
    for dablog in $(ls -1t "${LATEST_DAB_DIR}"/DAB_*_stderr.log 2>/dev/null | head -n 20); do
      CH="$(basename "${dablog}" | sed -n 's/^DAB_\(.*\)_stderr\.log$/\1/p')"
      ENS="$(grep "ensemblenameHandler:" "${dablog}" | head -n1 | sed "s/.*ensemblenameHandler: \('[^']*'\).*\((EId [^)]*)\).*/\1 \2/")"
      if [ ! -z "${CH}" ] && [ ! -z "${ENS}" ]; then
        echo "  DAB ${CH} ${ENS}"
      fi
    done
  } | tac)"
fi

RAM_STATIONS="${FM_FROM_RAM}"
if [ ! -z "${DAB_FROM_RAM}" ]; then
  if [ ! -z "${RAM_STATIONS}" ]; then
    RAM_STATIONS="${RAM_STATIONS}
${DAB_FROM_RAM}"
  else
    RAM_STATIONS="${DAB_FROM_RAM}"
  fi
fi

  cat gpscoor.log
  if [ -d /sys/class/thermal/thermal_zone0 ]; then
    #CPUTEMPS=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sed -e 's/\([0-9][0-9][0-9]\)$/.\1/g' | tr '\n' ' ')
    CPUTEMPS=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sed -e 's/\([0-9]\)\([0-9][0-9]\)$/.\1/g' | tr '\n' ' ')
    #CPUFREQS=$(cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_cur_freq 2>/dev/null | sed -e 's/\([0-9][0-9][0-9]\)$/.\1/g' | tr '\n' ' ')
    CPUFREQS=$(sudo cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_cur_freq 2>/dev/null | sed -e 's/\([0-9][0-9][0-9]\)$//g' | tr '\n' ' ')
    CPUSTATUS=""
    if [ ! -z "${CPUTEMPS}" ]; then
      CPUSTATUS="Temperature: ${CPUTEMPS}deg"
    fi
    if [ ! -z "${CPUFREQS}" ]; then
      CPUSTATUS="${CPUSTATUS}  CPU Freq(s): ${CPUFREQS}MHz"
    fi
    echo "${CPUSTATUS}"
  fi
  # Always show current scanning band edges if available
  if [ -f scanner.log ]; then
    CHECK_LINE=$(grep -E "rtl_sdr -s |dab-rtlsdr -C " scanner.log | tail -n1)
    if [ ! -z "${CHECK_LINE}" ]; then
      DAB_CH=$(echo "${CHECK_LINE}" | sed -n 's/.*dab-rtlsdr -C \([^ ]*\).*/\1/p')
      if [ ! -z "${DAB_CH}" ]; then
        echo -e "\nchecking DAB ${DAB_CH}"
      else
        CENTER=$(echo "${CHECK_LINE}" | sed -n 's/.*-f \([0-9][0-9]*\).*/\1/p')
        BW=$(echo "${CHECK_LINE}" | sed -n 's/.*-w \([0-9][0-9]*\).*/\1/p')
        if [ -z "${BW}" ]; then
          BW_KHZ=$(echo "${CHECK_LINE}" | sed -n 's/.*bw=\([0-9][0-9]*\).*/\1/p')
          if [ ! -z "${BW_KHZ}" ]; then
            BW=$[ ${BW_KHZ} * 1000 ]
          fi
        fi
        if [ -z "${BW}" ]; then
          BW=$(echo "${CHECK_LINE}" | sed -n 's/.*-s \([0-9][0-9]*\).*/\1/p')
        fi
        if [ ! -z "${CENTER}" ] && [ ! -z "${BW}" ]; then
          FM_CENTER_MHz=$((CENTER / 1000000)).$(printf '%02d' $(((CENTER % 1000000) / 10000)))
          FM_HALFBW=$[ ${BW} / 2 ]
          FM_HALFBW_MHz=$((FM_HALFBW / 1000000)).$(printf '%02d' $(((FM_HALFBW % 1000000) / 10000)))
          echo -e "\nchecking FM around ${FM_CENTER_MHz} MHz (+/- ${FM_HALFBW_MHz} MHz)"
        elif [ ! -z "${CENTER}" ]; then
          FM_CENTER_MHz=$((CENTER / 1000000)).$(printf '%02d' $(((CENTER % 1000000) / 10000)))
          echo -e "\nchecking FM around ${FM_CENTER_MHz} MHz"
        fi
      fi
    fi
  fi
  # Show found stations if any exist
  if [ -f LAST.history ] && [ -s LAST.history ] && [ $(wc -l < LAST.history) -gt 1 ]; then
    echo "Last found stations:"
    tail -n 3 LAST.history | awk '{
      if ($1 == "FM") {
        freq = $2
        sub(/0000$/, "", freq)
        freq = substr(freq, 1, length(freq)-2) "." substr(freq, length(freq)-1)
        printf "  FM %-10s", freq " MHz"
        if (NF >= 3) {
          pi = $3
          sub(/^0x/, "", pi)
          printf " %s", pi
        }
        for (i = 4; i <= NF; i++) printf " %s", $i
        printf "\n"
      } else if ($1 ~ /^DAB_/) {
        sub(/^DAB_/, "DAB ", $1)
        printf "  %s", $1
        for (i = 2; i <= NF; i++) printf " %s", $i
        printf "\n"
      } else {
        print "  " $0
      }
    }'
  elif [ ! -z "${RAM_STATIONS}" ]; then
    echo "Last found stations:"
    echo "${RAM_STATIONS}" | tail -n 3
  elif [ -f LAST ] && [ -s LAST ] && grep -Eq '^(FM [0-9]+|DAB_)' LAST; then
    echo -en "\nLast found station: "
    sed -e 's/0000$//g' -e 's/\([0-9][0-9]\)$/.\1 MHz/g' -e 's/^DAB_/DAB /' LAST | tr -d '\n'
    if [ -f LAST.info ]; then
      echo -n " "
      cat LAST.info
    else
      echo ""
    fi
  else
    :
  fi

  # Always show delta time when LAST file exists
  if [ -f ${FMLIST_SCAN_RAM_DIR}/LAST ] && [ -s ${FMLIST_SCAN_RAM_DIR}/LAST ]; then
    CURR="$(date -u +%s)"
    LAST="$(stat -c %Y ${FMLIST_SCAN_RAM_DIR}/LAST)"
    D=$[ $CURR - $LAST ]
    echo "Delta from LAST to CURR = $D secs"
  fi

  if screen -list |grep -q "scanLoopBg" ; then
    echo "Scanner scanLoop is running in screen."
  else
    echo -e "Scanner scanLoop is \n===========\n   NOT  \n===========\nrunning in screen."
  fi

  echo ""
  tail -n 10 checkBgScanLoop.log | grep -v "Delta from LAST to CURR"

  echo ""
  ( echo "uniq (incl. dupl.), #DAB Ens., #DAB prg, #FM prg" ; SKIP_SCANNED=1 SKIP_MISSING=1 SKIP_ADD=1 scanEvalSummary.sh | awk -F, '{ OFS=","; print $1, $3, $5, $7; }' ) \
    | sed 's/^40,/scanned,/g' |sed 's/^41,/missed,/g' |sed 's/^42,/additional,/g' |sed 's/^43,/refs,/g' \
    | column -s , -t
