#!/bin/bash

SCRIPT=$(realpath -s "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")

if [ -z "${FMLIST_SCAN_RAM_DIR}" ]; then
  source $HOME/.config/fmlist_scan/config
  if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
    mkdir -p "${FMLIST_SCAN_RAM_DIR}"
  fi
else
  # Ensure FMLIST_UP_POSITION is available even if FMLIST_SCAN_RAM_DIR was already set
  source $HOME/.config/fmlist_scan/config 2>/dev/null
fi

export LC_ALL=C
cd "${FMLIST_SCAN_RAM_DIR}"

SCANLOOP_RUNNING="0"
if screen -list | grep -q "scanLoopBg" ; then
  SCANLOOP_RUNNING="1"
fi

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
      if (ps == "________") ps = "        "
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

  GPS_DISPLAY="$(cat gpscoor.log | sed 's/\.[0-9]*Z/Z/g')"
  echo -n "${GPS_DISPLAY}"
  
  # Add position mode (fixed/mobile) on same line
  if [ ! -z "${FMLIST_UP_POSITION}" ]; then
    if [ "${FMLIST_UP_POSITION}" = "fixed" ]; then
      echo " / fixed position"
    elif [ "${FMLIST_UP_POSITION}" = "mobile" ]; then
      echo " / mobile position"
    else
      echo ""
    fi
  else
    echo ""
  fi
  
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
  PRESCAN_ACTIVE="0"
  if [ "${SCANLOOP_RUNNING}" = "1" ] && pgrep -x prescanDAB >/dev/null 2>&1; then
    PRESCAN_ACTIVE="1"
    PRESCAN_LINE=""
    if [ -f scanner.log ]; then
      PRESCAN_LINE=$(grep "running prescanDAB " scanner.log | tail -n1)
    fi
    PRESCAN_CHS=""
    PRESCAN_NUM=""
    if [ ! -z "${PRESCAN_LINE}" ]; then
      PRESCAN_CHS=$(echo "${PRESCAN_LINE}" | sed -n 's/.* -L \([^ ]*\) \.\./\1/p')
      if [ ! -z "${PRESCAN_CHS}" ]; then
        PRESCAN_NUM=$[ $(echo "${PRESCAN_CHS}" | tr -cd ',' | wc -c) + 1 ]
      fi
    fi
    if [ ! -z "${PRESCAN_NUM}" ]; then
      echo -e "\nprescanning DAB channels [${PRESCAN_NUM}]"
    else
      echo -e "\nprescanning DAB channels"
    fi
  fi

  if [ "${SCANLOOP_RUNNING}" = "1" ] && [ -f scanner.log ] && [ "${PRESCAN_ACTIVE}" = "0" ]; then
    CHECK_LINE=$(grep -E "rtl_sdr -s [0-9]+ -n [0-9]+ -f |rtl_sdr .*DAB_.*sec[^ ]*\.raw|abra-rtlsdr -C |dab-rtlsdr -C |abra-raw -F |dab-raw -F " scanner.log | tail -n1)
    if [ ! -z "${CHECK_LINE}" ]; then
      DAB_CH=$(echo "${CHECK_LINE}" | sed -n 's/.*\(abra-rtlsdr\|dab-rtlsdr\) -C \([^ ]*\).*/\2/p')
      DAB_RAW_CH=""
      if echo "${CHECK_LINE}" | grep -Eq "abra-raw -F |dab-raw -F "; then
        DAB_RAW_CH=$(echo "${CHECK_LINE}" | sed -n 's#.*DAB_\([^_]*\)_.*#\1#p')
      fi
      if [ ! -z "${DAB_CH}" ]; then
        echo -e "\nchecking DAB ${DAB_CH}"
      elif [ ! -z "${DAB_RAW_CH}" ]; then
        echo -e "\nanalysing DAB ${DAB_RAW_CH}"
      else
        DAB_REC_CH=$(echo "${CHECK_LINE}" | sed -n 's#.*DAB_\([^_ ]*\)_[^ ]*sec[^ ]*\.raw.*#\1#p')
        if [ ! -z "${DAB_REC_CH}" ]; then
          DAB_REC_FILE=$(echo "${CHECK_LINE}" | awk '{ print $NF }')
          DAB_REC_DUR=$(echo "${DAB_REC_FILE}" | sed -n 's#.*_\([0-9][0-9]*\)sec[^ ]*\.raw#\1#p')
          if [ -z "${DAB_REC_DUR}" ]; then
            DAB_REC_DUR="${FMLIST_SCAN_DAB_RAW_DURATION_SEC}"
          fi
          DAB_REC_BYTES_EXP=$[ ${DAB_REC_DUR} * 4096000 ]
          DAB_REC_BYTES_ACT="0"
          if [ -f "${DAB_REC_FILE}" ]; then
            DAB_REC_BYTES_ACT=$(stat -c %s "${DAB_REC_FILE}" 2>/dev/null)
          fi
          if [ -z "${DAB_REC_BYTES_ACT}" ]; then
            DAB_REC_BYTES_ACT="0"
          fi
          DAB_REC_SEC_ACT=$[ ${DAB_REC_BYTES_ACT} / 4096000 ]
          if [ ${DAB_REC_SEC_ACT} -gt ${DAB_REC_DUR} ]; then
            DAB_REC_SEC_ACT=${DAB_REC_DUR}
          fi
          if [ ${DAB_REC_BYTES_EXP} -gt 0 ]; then
            DAB_REC_PCT=$[ ${DAB_REC_BYTES_ACT} * 100 / ${DAB_REC_BYTES_EXP} ]
          else
            DAB_REC_PCT="0"
          fi
          if [ ${DAB_REC_PCT} -gt 100 ]; then
            DAB_REC_PCT="100"
          fi
          DAB_REC_BAR=$(awk -v p="${DAB_REC_PCT}" 'BEGIN { n=20; f=int((p*n)/100); if (f>n) f=n; for (i=0; i<n; ++i) s = s ((i<f) ? "#" : "-"); print s }')
          echo -e "\nrecording DAB ${DAB_REC_CH} [${DAB_REC_BAR}] ${DAB_REC_SEC_ACT}/${DAB_REC_DUR} sec"
          CHECK_LINE=""
        fi
      fi

      # Only display FM checking if FM scanning is enabled (not "0" or "OFF")
      if [ ! -z "${CHECK_LINE}" ] && [ -z "${DAB_CH}" ] && [ -z "${DAB_RAW_CH}" ] && [ "${FMLIST_SCAN_FM}" != "0" ] && [ "${FMLIST_SCAN_FM}" != "OFF" ]; then
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
        start_i = 3
        if (NF >= 3) {
          v3 = $3
          v3n = v3
          sub(/^0x/, "", v3n)
          if (v3n ~ /^[0-9A-Fa-f]{4}$/) {
            printf " %s", toupper(v3n)
            start_i = 4
          } else {
            if (v3 == "________") v3 = "        "
            printf " %s", v3
            start_i = 4
          }
        }
        for (i = start_i; i <= NF; i++) {
          v = $i
          if (v == "________") v = "        "
          printf " %s", v
        }
        printf "\n"
      } else if ($1 ~ /^DAB_/) {
        line = $0
        sub(/^DAB_/, "DAB ", line)
        print "  " line
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
      awk '{
        for (i = 1; i <= NF; i++) {
          if ($i == "________") $i = "        "
        }
        print
      }' LAST.info
    else
      echo ""
    fi
  else
    :
  fi

  QTH_PREFIX_SHOW="${FMLIST_QTH_PREFIX}"
  if [ -z "${QTH_PREFIX_SHOW}" ]; then
    QTH_PREFIX_SHOW="local"
  fi
  REF_DAB_ENS_FILE="${HOME}/.config/fmlist_scan/${QTH_PREFIX_SHOW}_dab_ensembles.csv"
  LAST_NEW_ENS_MSG_FILE="${HOME}/.config/fmlist_scan/${QTH_PREFIX_SHOW}_last_new_ensemble.txt"
  if [ -f "${REF_DAB_ENS_FILE}" ]; then
    if [ -f "${LAST_NEW_ENS_MSG_FILE}" ] && [ -s "${LAST_NEW_ENS_MSG_FILE}" ]; then
      echo ""
      cat "${LAST_NEW_ENS_MSG_FILE}"
      echo ""
    fi
  fi

  # Always show delta time when LAST file exists
  if [ -f ${FMLIST_SCAN_RAM_DIR}/LAST ] && [ -s ${FMLIST_SCAN_RAM_DIR}/LAST ]; then
    CURR="$(date -u +%s)"
    LAST="$(stat -c %Y ${FMLIST_SCAN_RAM_DIR}/LAST)"
    D=$[ $CURR - $LAST ]
    echo "Delta from LAST to CURR = $D secs"
  fi

  if [ "${SCANLOOP_RUNNING}" = "1" ]; then
    echo "Scanner scanLoop is running in screen."
  else
    echo -e "Scanner scanLoop is \n===========\n   NOT  \n===========\nrunning in screen."
  fi

  echo ""
  tail -n 10 checkBgScanLoop.log 2>/dev/null \
    | grep -v "Delta from LAST to CURR" \
    | grep -v "No LAST scan results. Setting to CURR - FMLIST_SCAN_DEAD_TIME"

  echo ""
  ( echo "uniq (incl. dupl.), #DAB Ens., #DAB prg, #FM prg" ; SKIP_SCANNED=1 SKIP_MISSING=1 SKIP_ADD=1 "${SCRIPTPATH}/scanEvalSummary.sh" 2>/dev/null | awk -F, '{ OFS=","; print $1, $3, $5, $7; }' ) \
    | sed 's/^40,/scanned,/g' |sed 's/^41,/missed,/g' |sed 's/^42,/additional,/g' |sed 's/^43,/refs,/g' \
    | column -s , -t
