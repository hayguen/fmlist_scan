#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

function chanFreq() {
  chan="$1"
  freqK=""
  case $chan in
  5A)  freqK="174928" ;;
  5B)  freqK="176640" ;;
  5C)  freqK="178352" ;;
  5D)  freqK="180064" ;;
  6A)  freqK="181936" ;;
  6B)  freqK="183648" ;;
  6C)  freqK="185360" ;;
  6D)  freqK="187072" ;;
  7A)  freqK="188928" ;;
  7B)  freqK="190640" ;;
  7C)  freqK="192352" ;;
  7D)  freqK="194064" ;;
  8A)  freqK="195936" ;;
  8B)  freqK="197648" ;;
  8C)  freqK="199360" ;;
  8D)  freqK="201072" ;;
  9A)  freqK="202928" ;;
  9B)  freqK="204640" ;;
  9C)  freqK="206352" ;;
  9D)  freqK="208064" ;;
  10A) freqK="209936" ;;
  10B) freqK="211648" ;;
  10C) freqK="213360" ;;
  10D) freqK="215072" ;;
  11A) freqK="216928" ;;
  11B) freqK="218640" ;;
  11C) freqK="220352" ;;
  11D) freqK="222064" ;;
  12A) freqK="223936" ;;
  12B) freqK="225648" ;;
  12C) freqK="227360" ;;
  12D) freqK="229072" ;;
  13A) freqK="230748" ;;
  13B) freqK="232496" ;;
  13C) freqK="234208" ;;
  13D) freqK="235776" ;;
  13E) freqK="237488" ;;
  13F) freqK="239200" ;;
  LA)  freqK="1452960" ;;
  LB)  freqK="1454672" ;;
  LC)  freqK="1456384" ;;
  LD)  freqK="1458096" ;;
  LE)  freqK="1459808" ;;
  LF)  freqK="1461520" ;;
  LG)  freqK="1463232" ;;
  LH)  freqK="1464944" ;;
  LI)  freqK="1466656" ;;
  LJ)  freqK="1468368" ;;
  LK)  freqK="1470080" ;;
  LL)  freqK="1471792" ;;
  LM)  freqK="1473504" ;;
  LN)  freqK="1475216" ;;
  LO)  freqK="1476928" ;;
  LP)  freqK="1478640" ;;
  *) ;;
  esac
  if [ ! -z "$freqK" ]; then
    echo -n "${freqK}e3"
  fi
}

function filterDabOptForRaw() {
  local in="$1"
  local -a arr out
  local i=0
  read -r -a arr <<< "${in}"
  while [ $i -lt ${#arr[@]} ]; do
    local tok="${arr[$i]}"
    case "${tok}" in
      -Q|-x)
        # strip flags with no argument
        ;;
      -W|-A|-E)
        # strip with argument (added explicitly for raw mode)
        i=$[ $i + 1 ]
        ;;
      -G|-C|-d|-s)
        # strip tuner device/frequency flags with argument
        i=$[ $i + 1 ]
        ;;
      -t|-a|-r|-p|-O)
        # strip live-tuner/device-specific options with argument
        i=$[ $i + 1 ]
        ;;
      *)
        out+=("${tok}")
        ;;
    esac
    i=$[ $i + 1 ]
  done
  # Use printf so leading dash options (e.g. -E) are not interpreted by echo.
  printf '%s\n' "${out[*]}"
}

function filterDabOptForDiscovery() {
  local in="$1"
  local -a arr out
  local i=0
  read -r -a arr <<< "${in}"
  while [ $i -lt ${#arr[@]} ]; do
    local tok="${arr[$i]}"
    case "${tok}" in
      -D)
        ;;
      *)
        out+=("${tok}")
        ;;
    esac
    i=$[ $i + 1 ]
  done
  printf '%s\n' "${out[*]}"
}

function getDabEnsembleKeyFromLog() {
  local CH="$1"
  local LOGFILE="$2"
  local KEY=""

  if [ -f "${LOGFILE}" ]; then
    KEY=$( awk -F',' -v ch="\"${CH}\"" '$2=="CSV_ENSEMBLE" && $3==ch { print $4 "," $5; exit }' "${LOGFILE}" )
  fi

  echo -n "${KEY}"
}

function refEnsembleKeyExists() {
  local KEY="$1"
  local REF_FILE="$2"

  awk -F',' -v key="${KEY}" '
    {
      cand = ""
      if (NF >= 3 && ($1 ~ /^"[0-9]{1,2}[A-Z]"$/ || $1 ~ /^"L[A-Z]"$/)) {
        cand = $2 "," $3
      } else if (NF >= 2) {
        cand = $1 "," $2
      }
      if (cand == key) {
        found = 1
        exit
      }
    }
    END { if (found) exit 0; else exit 1 }
  ' "${REF_FILE}"
}

function getDabEnsembleIdFromStderr() {
  local ERRFILE="$1"
  local EID=""

  if [ -f "${ERRFILE}" ]; then
    EID=$( sed -n "s/.*(EId \([^)]*\)).*/\1/p" "${ERRFILE}" | head -n1 )
  fi

  if [ -z "${EID}" ]; then
    EID="unknown"
  fi

  # Keep filename-safe characters only.
  EID=$( echo "${EID}" | tr -cd 'A-Za-z0-9._-' )
  if [ -z "${EID}" ]; then
    EID="unknown"
  fi
  echo -n "${EID}"
}

if [ "${FMLIST_SPORADIC_E_MODE}" = "1" ] && [ -f ${FMLIST_SCAN_RAM_DIR}/is_daylight ]; then
  export FMLIST_SCAN_FM="1"
  export FMLIST_SCAN_DAB="0"
  echo "DAB scan is deactivated with FMLIST_SPORADIC_E_MODE=${FMLIST_SPORADIC_E_MODE} in $HOME/.config/fmlist_scan/config"
  exit 0
fi

if [ "${FMLIST_SCAN_DAB}" = "0" ] || [ "${FMLIST_SCAN_DAB}" = "OFF" ]; then
  echo "DAB scan is deactivated with FMLIST_SCAN_DAB=${FMLIST_SCAN_DAB} in $HOME/.config/fmlist_scan/config"
  exit 0
fi


DTF="$(date -u "+%Y-%m-%dT%T.%N Z")"
DTFREC="$(date -u "+%Y-%m-%dT%H%M%S")"
TBEG="$(date -u +%s)"

rec_path="${FMLIST_SCAN_RAM_DIR}/scan_${DTFREC}_DAB"
if [ ! -z "$1" ]; then
  rec_path="${FMLIST_SCAN_RAM_DIR}/$1"
fi
if [ ! -d "${rec_path}" ]; then
  mkdir -p "${rec_path}"
fi

echo "DAB scan started at ${DTF}"
echo "DAB scan started at ${DTF}" >${rec_path}/scan_duration.txt

# get ${GPSSRC} for use in dabscan.inc
GPSVALS=$( ( flock -s 213 ; cat ${FMLIST_SCAN_RAM_DIR}/gpscoor.inc 2>/dev/null ) 213>${FMLIST_SCAN_RAM_DIR}/gps.lock )
echo "${GPSVALS}" >${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
source ${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
rm ${FMLIST_SCAN_RAM_DIR}/gpsvals.inc


if [ ! -f ${FMLIST_SCAN_RAM_DIR}/dabscan.inc ]; then
  if [ -f $HOME/.config/fmlist_scan/dabscan.inc ]; then
    cp $HOME/.config/fmlist_scan/dabscan.inc ${FMLIST_SCAN_RAM_DIR}/
    echo "copied scan parameters from $HOME/.config/fmlist_scan/dabscan.inc to ${FMLIST_SCAN_RAM_DIR}/dabscan.inc. edit this file for use with next scan."
  else
    cat - <<'EOF' >${FMLIST_SCAN_RAM_DIR}/dabscan.inc
chanlist=dab_chanlist.txt
DABOPT="-Q -A 2000 -E 3 -W 5000 -c"
EOF
    echo "wrote default scan parameters to ${FMLIST_SCAN_RAM_DIR}/dabscan.inc. edit this file for use with next scan."
  fi
fi

if [ -f "${FMLIST_SCAN_RAM_DIR}/fmscan.no" ]; then
  export DABSCAN_NO=$( cat "${FMLIST_SCAN_RAM_DIR}/dabscan.no" )
else
  export DABSCAN_NO="0"
fi
export DABSCAN_NO=$[ ${DABSCAN_NO} + 1 ]

echo "reading scan parameters (chanlist, DABOPT) from ${FMLIST_SCAN_RAM_DIR}/dabscan.inc"
source ${FMLIST_SCAN_RAM_DIR}/dabscan.inc

echo -n "${DABSCAN_NO}" >${FMLIST_SCAN_RAM_DIR}/dabscan.no


if [ ! -z "${FMLIST_SCAN_PPM}" ]; then
  DABOPT="${DABOPT} -p ${FMLIST_SCAN_PPM}"
fi

if [ -z "${FMLIST_DAB_RTLSDR_DEV}" ]; then
  FMLIST_DAB_RTLSDR_OPT=""
else
  FMLIST_DAB_RTLSDR_OPT="-d ${FMLIST_DAB_RTLSDR_DEV}"
fi

if [ -z "${FMLIST_SCAN_DAB_ANALYZE_FROM_RAW}" ]; then
  FMLIST_SCAN_DAB_ANALYZE_FROM_RAW="0"
fi
if [ -z "${FMLIST_SCAN_DAB_RAW_DURATION_SEC}" ]; then
  FMLIST_SCAN_DAB_RAW_DURATION_SEC="15"
fi
if [ -z "${FMLIST_SCAN_DAB_RAW_INIT_MS}" ]; then
  FMLIST_SCAN_DAB_RAW_INIT_MS="5000"
fi

# fixed position uses detailed analysis and always runs through raw-file workflow
IS_FIXED_POSITION="0"
if [ "${FMLIST_UP_POSITION}" = "fixed" ] || [ "${FMLIST_UP_POSITION}" = "fixed position" ]; then
  IS_FIXED_POSITION="1"
fi

if [ "${IS_FIXED_POSITION}" = "1" ] && [[ " ${DABOPT} " != *" -D "* ]]; then
  DABOPT="${DABOPT} -D"
fi

if [ "${IS_FIXED_POSITION}" = "1" ] && [ "${FMLIST_SCAN_DAB_ANALYZE_FROM_RAW}" != "1" ]; then
  FMLIST_SCAN_DAB_ANALYZE_FROM_RAW="1"
  echo "${DTF}: fixed position: forcing FMLIST_SCAN_DAB_ANALYZE_FROM_RAW=1 to avoid prolonged live detailed analysis" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
fi

# CSV output is required for ensemble/program extraction and reference-file updates.
if [[ " ${DABOPT} " != *" -c "* ]]; then
  DABOPT="${DABOPT} -c"
fi

if [ "${FMLIST_SCAN_DAB_SAVE_FIC}" = "1" ]; then
  DABOPT="${DABOPT} -f"
fi

DABOPT_RAW="$( filterDabOptForRaw "${DABOPT}" )"
# Keep one fixed clip per channel/service and rewind for each detailed analysis pass.
# Use -E 0 for file analysis: no need to wait for ensemble sync blocks in a pre-recorded file.
DABOPT_RAW="${DABOPT_RAW} -E 0 -W ${FMLIST_SCAN_DAB_RAW_INIT_MS} -A 0 -X -Y"
# Add -D for fixed position; for mobile, will add -D only if ensemble is new
if [ "${FMLIST_UP_POSITION}" = "fixed" ] || [ "${FMLIST_UP_POSITION}" = "fixed position" ]; then
  if [[ " ${DABOPT_RAW} " != *" -D "* ]]; then
    DABOPT_RAW="${DABOPT_RAW} -D"
  fi
fi
DABOPT_DISCOVERY="$( filterDabOptForDiscovery "${DABOPT}" )"

DAB_RTLSDR_BIN="$(command -v dab-rtlsdr 2>/dev/null)"
DAB_RAW_BIN="$(command -v dab-raw 2>/dev/null)"
if [ -x "${HOME}/.local/bin/dab-rtlsdr" ]; then
  DAB_RTLSDR_BIN="${HOME}/.local/bin/dab-rtlsdr"
fi
if [ -x "${HOME}/.local/bin/dab-raw" ]; then
  DAB_RAW_BIN="${HOME}/.local/bin/dab-raw"
fi
if [ -z "${DAB_RTLSDR_BIN}" ]; then
  DAB_RTLSDR_BIN="dab-rtlsdr"
fi
if [ -z "${DAB_RAW_BIN}" ]; then
  DAB_RAW_BIN="dab-raw"
fi

if [ "${FMLIST_SCAN_DAB_ANALYZE_FROM_RAW}" = "1" ] && [ -z "${DAB_RAW_BIN}" ]; then
  echo "dab-raw not found in PATH/.local. Falling back to live dab-rtlsdr." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  FMLIST_SCAN_DAB_ANALYZE_FROM_RAW="0"
fi

if [ "${FMLIST_SCAN_DAB_ANALYZE_FROM_RAW}" = "1" ] && [ ! -z "${DAB_RAW_BIN}" ]; then
  DABRAW_HELP="$("${DAB_RAW_BIN}" -h 2>&1 || true)"
  if echo "${DABRAW_HELP}" | grep -q "detailed audio analysis"; then
    echo "${DTF}: using dab-raw binary ${DAB_RAW_BIN} (supports -D detailed analysis)" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  else
    echo "${DTF}: WARNING: dab-raw binary ${DAB_RAW_BIN} may not support -D detailed analysis" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  fi
fi

REF_DAB_ENS_FILE="${HOME}/.config/fmlist_scan/${FMLIST_QTH_PREFIX}_dab_ensembles.csv"
if [ "${FMLIST_SCAN_DAB_ANALYZE_FROM_RAW}" = "1" ]; then
  REF_DAB_ENS_DIR="$(dirname "${REF_DAB_ENS_FILE}")"
  if [ ! -d "${REF_DAB_ENS_DIR}" ]; then
    mkdir -p "${REF_DAB_ENS_DIR}"
  fi
  if [ ! -f "${REF_DAB_ENS_FILE}" ]; then
    : >"${REF_DAB_ENS_FILE}"
    echo "${DTF}: DAB: created ensemble reference file ${REF_DAB_ENS_FILE}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  fi
fi

chanpath="${FMLIST_SCAN_RAM_DIR}/${chanlist}"
echo "chanpath=${chanpath}"
if [ ! -f "${chanpath}" ]; then
  echo "chanpath does not exist"
  if [ -f "${HOME}/.config/fmlist_scan/${chanlist}" ]; then
    echo "copying chanlist "${HOME}/.config/fmlist_scan/${chanlist}" to ${chanpath}"
    echo "copying chanlist "${HOME}/.config/fmlist_scan/${chanlist}" to ${chanpath}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    cp "${HOME}/.config/fmlist_scan/${chanlist}" "${chanpath}"
  else
    echo "Error: cannot find channellist file ${chanlist} configured in ${FMLIST_SCAN_RAM_DIR}/dabscan.inc !"
    exit 10
  fi
fi

if /bin/false; then
  echo "usage: $0 [<result dir> [<minSNR> [<maxWaitForClock>] ] ]"
  echo "scanning with channel list '${chanlist}' writing results to '${rec_path}'"
  echo "options: besides channel '-C ${CH}' using: '${DABOPT}'"
  echo "  -Q: silence"
  echo "  -E snr: scan channel .. and abort decoding with SNR below some level"
  echo "  -A 2000: additional 2000 ms from finding of ensemble"
  echo ""
fi

echo "" >>${FMLIST_SCAN_RAM_DIR}/scanner.log


if [ ${FMLIST_SCAN_DAB_USE_PRESCAN} -ne 0 ]; then
  allchans=$( tr '\n' ',' <"${chanpath}" |sed 's#,$##g' )
  echo "running prescanDAB -W 64 -A 2 -C ${FMLIST_SCAN_DAB_MIN_AUTOCORR} ${DABPRESCANOPT} -L ${allchans} .." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  prescanDAB -W 64 -A 2 -C ${FMLIST_SCAN_DAB_MIN_AUTOCORR} ${DABPRESCANOPT} -L "${allchans}" >${FMLIST_SCAN_RAM_DIR}/dabscanout.inc
  echo "" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  cat ${FMLIST_SCAN_RAM_DIR}/dabscanout.inc >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  . ${FMLIST_SCAN_RAM_DIR}/dabscanout.inc
  #echo ${#dabchannels[@]} ${dabchannels[@]}
else
  allchans=$( tr '\n' ' ' <"${chanpath}" )
  dabchannels=( ${allchans} )
fi

rm -f ${rec_path}/*_DAB_*.fic 2>/dev/null

if [ -z "${FMLIST_SCAN_DAB_RAW_PARALLEL_JOBS}" ]; then
  FMLIST_SCAN_DAB_RAW_PARALLEL_JOBS="1"
fi
if [ "${FMLIST_SCAN_DAB_RAW_PARALLEL_JOBS}" -lt 1 ]; then
  FMLIST_SCAN_DAB_RAW_PARALLEL_JOBS="1"
fi
if [ "${FMLIST_SCAN_DAB_ANALYZE_FROM_RAW}" = "1" ] && [ "${FMLIST_SCAN_DAB_SAVE_FIC}" = "1" ] && [ "${FMLIST_SCAN_DAB_RAW_PARALLEL_JOBS}" -gt 1 ]; then
  echo "FIC save is enabled; forcing FMLIST_SCAN_DAB_RAW_PARALLEL_JOBS=1 to avoid ficdata.fic races." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  FMLIST_SCAN_DAB_RAW_PARALLEL_JOBS="1"
fi

function process_dab_channel_results() {
  local CH="$1"
  local CH_RAW="$2"
  local DTFFIC="$3"
  local KEEP_RAW_FILE="${4:-0}"
  local DTF_LOCAL="$(date -u "+%Y-%m-%dT%T.%N Z")"
  local GPSCOLS="$(cat "${rec_path}/DAB_${CH}.gpscols" 2>/dev/null)"

  grep ",CSV_ENSEMBLE," "${rec_path}/DAB_${CH}.log" | sed "s#,CSV_ENSEMBLE,#,${GPSCOLS},#g" >>"${rec_path}/dab_ensemble.csv"
  grep ",CSV_GPSCOOR,"  "${rec_path}/DAB_${CH}.log" | sed "s#,CSV_GPSCOOR,#,${GPSCOLS},#g"  >>"${rec_path}/dab_gps.csv"
  grep ",CSV_AUDIO,"    "${rec_path}/DAB_${CH}.log" | sed "s#,CSV_AUDIO,#,${GPSCOLS},#g"    >>"${rec_path}/dab_audio.csv"
  grep ",CSV_PACKET,"   "${rec_path}/DAB_${CH}.log" | sed "s#,CSV_PACKET,#,${GPSCOLS},#g"   >>"${rec_path}/dab_packet.csv"

  NP=$( cat "${rec_path}/DAB_${CH}_stderr.log" | grep " is part of the ensemble" | grep -c "^programnameHandler:" )
  NE=$( cat "${rec_path}/DAB_${CH}_stderr.log" | grep " is recognized" | grep -c "ensemblenameHandler:" )
  echo "DAB_ENSEMBLE=\"${NE}\"" >>"${rec_path}/DAB_channels.txt"
  echo "NUM_PROGRAMS=\"${NP}\"" >>"${rec_path}/DAB_channels.txt"

  if [ $NP -eq 0 ]; then
    if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
      echo "${DTF_LOCAL}: DAB ${CH}: NO station" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      mv "${rec_path}/DAB_${CH}.log" "${rec_path}/DAB_${CH}_no-station.log"
      mv "${rec_path}/DAB_${CH}_stderr.log" "${rec_path}/DAB_${CH}_no-station_stderr.log"
    else
      rm "${rec_path}/DAB_${CH}.log" "${rec_path}/DAB_${CH}_stderr.log"
    fi
  else
    ENSNAME=$( grep "ensemblenameHandler:" "${rec_path}/DAB_${CH}_stderr.log" | head -n1 | sed "s/.*ensemblenameHandler: \('[^']*'\).*\((EId [^)]*)\).*/\1 \2/" )

    LAST_KEY="DAB_${CH}"
    LAST_INFO="${ENSNAME}"
    (
      flock -x 214
      echo "${LAST_KEY}" >${FMLIST_SCAN_RAM_DIR}/LAST
      echo "${LAST_INFO}" >${FMLIST_SCAN_RAM_DIR}/LAST.info
      if [ -f ${FMLIST_SCAN_RAM_DIR}/LAST.history ]; then
        awk -v k="${LAST_KEY}" 'index($0, k " ") != 1' ${FMLIST_SCAN_RAM_DIR}/LAST.history >${FMLIST_SCAN_RAM_DIR}/LAST.history.tmp
      else
        : >${FMLIST_SCAN_RAM_DIR}/LAST.history.tmp
      fi
      echo "${LAST_KEY} ${LAST_INFO}" >>${FMLIST_SCAN_RAM_DIR}/LAST.history.tmp
      tail -n 50 ${FMLIST_SCAN_RAM_DIR}/LAST.history.tmp >${FMLIST_SCAN_RAM_DIR}/LAST.history
      rm -f ${FMLIST_SCAN_RAM_DIR}/LAST.history.tmp
    ) 214>${FMLIST_SCAN_RAM_DIR}/last.lock
    NUMFOUND=$[ $NUMFOUND + 1 ]

    if [ "${FMLIST_SCAN_DAB_SAVE_FIC}" = "1" ]; then
      mv ficdata.fic ${rec_path}/${DTFFIC}_DAB_${CH}.fic
    fi

    if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
      echo "${DTF_LOCAL}: DAB ${CH}: DETECTED station" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    fi
    if [ ${FMLIST_SCAN_FOUND_PWMTONE} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
      scanToneFeedback.sh found
    fi
    if [ ${FMLIST_SCAN_FOUND_LEDPLAY} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
      sudo -E $HOME/bin/rpi3b_led_next.sh
    fi
  fi

  if [ "${FMLIST_SCAN_DAB_ANALYZE_FROM_RAW}" = "1" ] && [ ! -z "${CH_RAW}" ]; then
    if [ -f "${CH_RAW}" ]; then
      if [ "${KEEP_RAW_FILE}" = "1" ]; then
        echo "${DTF_LOCAL}: DAB ${CH}: keeping raw clip (first-time ensemble) ${CH_RAW}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      else
        rm -f "${CH_RAW}"
        echo "${DTF_LOCAL}: DAB ${CH}: deleted raw clip ${CH_RAW}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      fi
    fi
  fi

  rm -f "${rec_path}/DAB_${CH}.gpscols" 2>/dev/null
}

NUMFOUND=0
for CH in $(echo "${dabchannels[@]}") ; do

  if [ -f "${FMLIST_SCAN_RAM_DIR}/stopScanLoop" ]; then
    break
  fi
  DTF="$(date -u "+%Y-%m-%dT%T.%N Z")"
  GPS="$($HOME/bin/get_gpstime.sh)"
  GPSV="$( ( flock -s 213 ; cat ${FMLIST_SCAN_RAM_DIR}/gpscoor.inc 2>/dev/null ) 213>${FMLIST_SCAN_RAM_DIR}/gps.lock )"
  echo "${GPSV}" >${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
  source ${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
  rm ${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
  GPSCOLS="${GPSLAT},${GPSLON},${GPSMODE},${GPSALT},${GPSTIM}"
  echo "${GPSCOLS}" >"${rec_path}/DAB_${CH}.gpscols"

  echo "${CH}"
  # outputs to DAB_${CH}.inc is just informal for later debugging
  #   cause easier to read than resulting .csv
  echo ""                    >>"${rec_path}/DAB_channels.txt"
  echo "# ${CH}"             >>"${rec_path}/DAB_channels.txt"
  echo "CHANNEL=\"${CH}\""   >>"${rec_path}/DAB_channels.txt"
  echo "CURRTIM=\"${DTF}\""  >>"${rec_path}/DAB_channels.txt"
  echo "# last GPS:  ${GPS}" >>"${rec_path}/DAB_channels.txt"
  echo "${GPSV}"             >>"${rec_path}/DAB_channels.txt"
  echo "DAB_USE_PRESCAN=\"${FMLIST_SCAN_DAB_USE_PRESCAN}\""   >>"${rec_path}/DAB_channels.txt"
  echo "DAB_MIN_AUTOCORR=\"${FMLIST_SCAN_DAB_MIN_AUTOCORR}\"" >>"${rec_path}/DAB_channels.txt"

  if [ -d /sys/class/thermal/thermal_zone0 ]; then
    echo -e "$(date -u "+%Y-%m-%dT%T Z"): Temperature at scanDAB.sh before dab-rtlsdr -C ${CH}: $(cat /sys/class/thermal/thermal_zone*/temp | tr '\n' ' ')" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    echo "$(date -u +%s), $(cat /sys/class/thermal/thermal_zone*/temp | tr '\n' ' ')" >>${FMLIST_SCAN_RAM_DIR}/cputemp.csv
  fi

  DTFFIC="$(date -u "+%Y-%m-%dT%H%M%S")"
  if [ "${FMLIST_SCAN_DAB_ANALYZE_FROM_RAW}" = "1" ]; then
    IS_NEW_ENS="0"
    SHOULD_REGISTER_NEW="0"
    KEEP_RAW_FILE="0"
    CH_RAW=""

    # Discovery pass: always use dab-rtlsdr without audio analysis (-D removed).
    "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_DISCOVERY} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"

    DAB_ENS_KEY="$( getDabEnsembleKeyFromLog "${CH}" "${rec_path}/DAB_${CH}.log" )"
    REF_DAB_ENS_FILE="${HOME}/.config/fmlist_scan/${FMLIST_QTH_PREFIX}_dab_ensembles.csv"

    if [ ! -z "${DAB_ENS_KEY}" ]; then
      # Write LAST immediately after discovery so monitor shows detected station without waiting for analysis
      DISC_ENSNAME=$( grep "ensemblenameHandler:" "${rec_path}/DAB_${CH}_stderr.log" | head -n1 | sed "s/.*ensemblenameHandler: \('[^']*'\).*\((EId [^)]*)\).*/\1 \2/" )
      if [ ! -z "${DISC_ENSNAME}" ]; then
        (
          flock -x 214
          echo "DAB_${CH}" >${FMLIST_SCAN_RAM_DIR}/LAST
          echo "${DISC_ENSNAME}" >${FMLIST_SCAN_RAM_DIR}/LAST.info
          if [ -f ${FMLIST_SCAN_RAM_DIR}/LAST.history ]; then
            awk -v k="DAB_${CH}" 'index($0, k " ") != 1' ${FMLIST_SCAN_RAM_DIR}/LAST.history >${FMLIST_SCAN_RAM_DIR}/LAST.history.tmp
          else
            : >${FMLIST_SCAN_RAM_DIR}/LAST.history.tmp
          fi
          echo "DAB_${CH} ${DISC_ENSNAME}" >>${FMLIST_SCAN_RAM_DIR}/LAST.history.tmp
          tail -n 50 ${FMLIST_SCAN_RAM_DIR}/LAST.history.tmp >${FMLIST_SCAN_RAM_DIR}/LAST.history
          rm -f ${FMLIST_SCAN_RAM_DIR}/LAST.history.tmp
        ) 214>${FMLIST_SCAN_RAM_DIR}/last.lock
      fi
      REF_DAB_ENS_DIR="$(dirname "${REF_DAB_ENS_FILE}")"
      if [ ! -d "${REF_DAB_ENS_DIR}" ]; then
        mkdir -p "${REF_DAB_ENS_DIR}"
      fi
      if [ ! -f "${REF_DAB_ENS_FILE}" ]; then
        : >"${REF_DAB_ENS_FILE}"
        echo "${DTF}: DAB ${CH}: created ensemble reference file ${REF_DAB_ENS_FILE}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      fi

      if refEnsembleKeyExists "${DAB_ENS_KEY}" "${REF_DAB_ENS_FILE}"; then
        IS_NEW_ENS="0"
      else
        IS_NEW_ENS="1"
        KEEP_RAW_FILE="1"
        echo "${DTF}: DAB ${CH}: new multiplex detected (${DAB_ENS_KEY})" >>${FMLIST_SCAN_RAM_DIR}/scanner.log

        QTH_PREFIX_SHOW="${FMLIST_QTH_PREFIX}"
        if [ -z "${QTH_PREFIX_SHOW}" ]; then
          QTH_PREFIX_SHOW="local"
        fi
        LAST_NEW_ENS_MSG_FILE="${HOME}/.config/fmlist_scan/${QTH_PREFIX_SHOW}_last_new_ensemble.txt"
        REG_CH="${CH}"
        REG_EID=$(echo "${DAB_ENS_KEY}" | awk -F',' '{print $1}')
        REG_EID_FMT=$(echo "${REG_EID}" | sed 's/^0[xX]//' | tr '[:lower:]' '[:upper:]')
        REG_ENS_NAME=$(echo "${DAB_ENS_KEY}" | awk -F',' '{print $2}' | sed 's/^"//; s/"$//; s/[[:space:]]*$//')
        REG_HM="$(date -u "+%H:%M")"
        if [ ! -z "${REG_ENS_NAME}" ] && [ ! -z "${REG_CH}" ] && [ ! -z "${REG_EID_FMT}" ]; then
          echo "new ensemble '${REG_ENS_NAME}' (EId ${REG_EID_FMT}) on channel ${REG_CH} detected at ${REG_HM} UTC" >>"${LAST_NEW_ENS_MSG_FILE}"
        else
          echo "new ensemble detected at ${REG_HM} UTC" >>"${LAST_NEW_ENS_MSG_FILE}"
        fi
      fi
    else
      echo "${DTF}: DAB ${CH}: no ensemble key extracted from discovery output" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    fi

    if { [ "${IS_FIXED_POSITION}" = "1" ] || [ "${IS_NEW_ENS}" = "1" ]; } && [ ! -z "${DAB_ENS_KEY}" ]; then
      RAW_DURATION_SEC="${FMLIST_SCAN_DAB_RAW_DURATION_SEC}"
      if [ "${IS_FIXED_POSITION}" = "1" ] && [ "${IS_NEW_ENS}" = "0" ]; then
        RAW_DURATION_SEC="5"
      fi
      CH_FREQ="$( chanFreq "${CH}" )"
      DTFRAW="$(date -u "+%Y%m%dT%H%M%SZ")"
      DAB_EID="$( getDabEnsembleIdFromStderr "${rec_path}/DAB_${CH}_stderr.log" )"
      CH_RAW="${rec_path}/DAB_${CH}_${DAB_EID}_${DTFRAW}_${RAW_DURATION_SEC}sec.raw"
      NSMP="$[ ${RAW_DURATION_SEC} * 2048000 ]"

      if [ -z "${CH_FREQ}" ]; then
        echo "${DTF}: DAB ${CH}: cannot map channel to frequency for raw capture" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      else
        echo "rtl_sdr -f ${CH_FREQ} -s 2048000 -n ${NSMP} ${FMLIST_DAB_RTLSDR_OPT} ${CH_RAW}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
        timeout -s SIGTERM -k 2 $[${RAW_DURATION_SEC} + 3] rtl_sdr -f ${CH_FREQ} -s 2048000 -n ${NSMP} ${FMLIST_DAB_RTLSDR_OPT} "${CH_RAW}" >"${rec_path}/DAB_${CH}_rtl.log" 2>&1
        RTL_RC=$?

        if { [ ${RTL_RC} -ne 0 ] && [ ${RTL_RC} -ne 124 ]; } || [ ! -s "${CH_RAW}" ]; then
          echo "${DTF}: DAB ${CH}: raw capture failed (rc=${RTL_RC}); keeping discovery-only result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
          CH_RAW=""
          KEEP_RAW_FILE="0"
        else
          if [ "${IS_NEW_ENS}" = "1" ]; then
            SHOULD_REGISTER_NEW="1"
          fi
          # For mobile position, add -D only if ensemble is new (to avoid heating RTL stick)
          DABOPT_RAW_FOR_ANALYSIS="${DABOPT_RAW}"
          if { [ "${FMLIST_UP_POSITION}" = "mobile" ] || [ -z "${FMLIST_UP_POSITION}" ]; } && [ "${IS_NEW_ENS}" = "1" ]; then
            if [[ " ${DABOPT_RAW_FOR_ANALYSIS} " != *" -D "* ]]; then
              DABOPT_RAW_FOR_ANALYSIS="${DABOPT_RAW_FOR_ANALYSIS} -D"
            fi
          fi
          # Adjust -W wait time based on clip duration: shorter clips need less sync wait time
          DABOPT_RAW_FOR_ANALYSIS=$(echo " ${DABOPT_RAW_FOR_ANALYSIS} " | sed -E "s/ -W [0-9]+ / -W $([ ${RAW_DURATION_SEC} -le 5 ] && echo 2000 || echo 5000) /g")
          echo "${DTF}: DAB ${CH}: dab-raw detailed audio analysis enabled" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
          echo "${DAB_RAW_BIN} -F ${CH_RAW} ${DABOPT_RAW_FOR_ANALYSIS}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
          "${DAB_RAW_BIN}" -F "${CH_RAW}" ${DABOPT_RAW_FOR_ANALYSIS} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
          DABRAW_RC=$?
          # Fix channel label in CSV output: dab-raw without -C writes internal sub-channel ID instead of band channel (e.g. "11C" instead of "6A")
          sed -i -E "s/(,CSV_(AUDIO|ENSEMBLE|GPSCOOR|PACKET),\")[^\"]*(\")/\1${CH}\3/g" "${rec_path}/DAB_${CH}.log"
          DABRAW_CSV_ENS=$(grep -c ",CSV_ENSEMBLE," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
          DABRAW_CSV_AUD=$(grep -c ",CSV_AUDIO," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
          DABRAW_TOO_WEAK_IN_CSV=$(grep -c ",CSV_AUDIO,.*too weak signal" "${rec_path}/DAB_${CH}.log" 2>/dev/null)
          if [ -z "${DABRAW_TOO_WEAK_IN_CSV}" ]; then DABRAW_TOO_WEAK_IN_CSV=0; fi

          # Detect too-weak: either no CSV at all, or CSV rows contain "too weak signal"
          DABRAW_TOO_WEAK="0"
          if [ ${DABRAW_CSV_ENS} -eq 0 ] && [ ${DABRAW_CSV_AUD} -eq 0 ]; then
            # Check stderr/log for too-weak hint when there's no CSV
            if grep -qi "too weak" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null || grep -qi "too weak" "${rec_path}/DAB_${CH}.log" 2>/dev/null; then
              DABRAW_TOO_WEAK="1"
            fi
          elif [ ${DABRAW_TOO_WEAK_IN_CSV} -gt 0 ]; then
            DABRAW_TOO_WEAK="1"
          fi

          if [ ${DABRAW_RC} -ne 0 ] && [ ${DABRAW_CSV_ENS} -eq 0 ] && [ ${DABRAW_CSV_AUD} -eq 0 ] && [ "${DABRAW_TOO_WEAK}" = "0" ]; then
            echo "${DTF}: DAB ${CH}: dab-raw failed (rc=${DABRAW_RC}) without CSV output and no 'too weak' hint; keeping discovery-only result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_DISCOVERY} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
          elif [ "${DABRAW_TOO_WEAK}" = "1" ] && [ "${IS_FIXED_POSITION}" = "1" ] && [ ! -z "${CH_FREQ}" ]; then
            # Fixed position: recapture with FMLIST_SCAN_DAB_RAW_DURATION_SEC (15s) and retry without rewind
            RETRY_RAW_DURATION="${FMLIST_SCAN_DAB_RAW_DURATION_SEC}"
            DTFRAW_RETRY="$(date -u "+%Y%m%dT%H%M%SZ")"
            CH_RAW_RETRY="${rec_path}/DAB_${CH}_${DAB_EID}_${DTFRAW_RETRY}_${RETRY_RAW_DURATION}sec.raw"
            NSMP_RETRY=$[ ${RETRY_RAW_DURATION} * 2048000 ]
            DABOPT_RAW_NOREWIND="$(echo " ${DABOPT_RAW_FOR_ANALYSIS} " | sed -E 's/[[:space:]]-X([[:space:]]|$)/ /g; s/[[:space:]]-Y([[:space:]]|$)/ /g; s/[[:space:]]-E[[:space:]]+[0-9]+/ -E 0/g; s/[[:space:]]-W [0-9]+/ -W 5000/g; s/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/ /g')"
            echo "${DTF}: DAB ${CH}: too weak signal; recapturing ${RETRY_RAW_DURATION}s and retrying without rewind" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            echo "rtl_sdr -f ${CH_FREQ} -s 2048000 -n ${NSMP_RETRY} ${FMLIST_DAB_RTLSDR_OPT} ${CH_RAW_RETRY}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            timeout -s SIGTERM -k 2 $[${RETRY_RAW_DURATION} + 3] rtl_sdr -f ${CH_FREQ} -s 2048000 -n ${NSMP_RETRY} ${FMLIST_DAB_RTLSDR_OPT} "${CH_RAW_RETRY}" >"${rec_path}/DAB_${CH}_rtl_retry.log" 2>&1
            RTL_RETRY_RC=$?
            if { [ ${RTL_RETRY_RC} -eq 0 ] || [ ${RTL_RETRY_RC} -eq 124 ]; } && [ -s "${CH_RAW_RETRY}" ]; then
              rm -f "${CH_RAW}" 2>/dev/null
              CH_RAW="${CH_RAW_RETRY}"
              echo "${DAB_RAW_BIN} -F ${CH_RAW} ${DABOPT_RAW_NOREWIND}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
              "${DAB_RAW_BIN}" -F "${CH_RAW}" ${DABOPT_RAW_NOREWIND} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
              sed -i -E "s/(,CSV_(AUDIO|ENSEMBLE|GPSCOOR|PACKET),\")[^\"]*(\")/\1${CH}\3/g" "${rec_path}/DAB_${CH}.log"
              DABRAW_CSV_ENS=$(grep -c ",CSV_ENSEMBLE," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
              DABRAW_CSV_AUD=$(grep -c ",CSV_AUDIO," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
              if [ ${DABRAW_CSV_ENS} -eq 0 ] && [ ${DABRAW_CSV_AUD} -eq 0 ]; then
                echo "${DTF}: DAB ${CH}: longer-clip retry produced no CSV; keeping discovery-only result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
                "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_DISCOVERY} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
              else
                echo "${DTF}: DAB ${CH}: longer-clip retry produced CSV; keeping dab-raw result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
              fi
            else
              echo "${DTF}: DAB ${CH}: longer-clip capture failed (rc=${RTL_RETRY_RC}); keeping discovery-only result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
              rm -f "${CH_RAW_RETRY}" 2>/dev/null
              "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_DISCOVERY} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
            fi
          elif [ "${DABRAW_TOO_WEAK}" = "1" ]; then
            # Mobile or no freq: retry without rewind on existing clip
            DABOPT_RAW_NOREWIND="$(echo " ${DABOPT_RAW_FOR_ANALYSIS} " | sed -E 's/[[:space:]]-X([[:space:]]|$)/ /g; s/[[:space:]]-Y([[:space:]]|$)/ /g; s/[[:space:]]-E[[:space:]]+[0-9]+/ -E 0/g; s/[[:space:]]-W [0-9]+/ -W $([ ${RAW_DURATION_SEC} -le 5 ] && echo 2000 || echo 5000)/g; s/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/ /g')"
            echo "${DTF}: DAB ${CH}: too weak signal; retrying without rewind on existing clip" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            echo "${DAB_RAW_BIN} -F ${CH_RAW} ${DABOPT_RAW_NOREWIND}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            "${DAB_RAW_BIN}" -F "${CH_RAW}" ${DABOPT_RAW_NOREWIND} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
            sed -i -E "s/(,CSV_(AUDIO|ENSEMBLE|GPSCOOR|PACKET),\")[^\"]*(\")/\1${CH}\3/g" "${rec_path}/DAB_${CH}.log"
            DABRAW_CSV_ENS=$(grep -c ",CSV_ENSEMBLE," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
            DABRAW_CSV_AUD=$(grep -c ",CSV_AUDIO," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
            if [ ${DABRAW_CSV_ENS} -eq 0 ] && [ ${DABRAW_CSV_AUD} -eq 0 ]; then
              echo "${DTF}: DAB ${CH}: no-rewind retry produced no CSV; keeping discovery-only result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
              "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_DISCOVERY} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
            else
              echo "${DTF}: DAB ${CH}: no-rewind retry produced CSV; keeping dab-raw result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            fi
          elif [ ${DABRAW_RC} -ne 0 ]; then
            echo "${DTF}: DAB ${CH}: dab-raw returned rc=${DABRAW_RC} but produced CSV output; keeping dab-raw result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
          fi
        fi
      fi
    fi

    if [ "${SHOULD_REGISTER_NEW}" = "1" ] && [ ! -z "${DAB_ENS_KEY}" ]; then
      {
        cat "${REF_DAB_ENS_FILE}" 2>/dev/null
        echo "${DAB_ENS_KEY}"
      } | sort -u >"${REF_DAB_ENS_FILE}.tmp"
      mv "${REF_DAB_ENS_FILE}.tmp" "${REF_DAB_ENS_FILE}"
      echo "${DTF}: DAB ${CH}: registered ensemble ${DAB_ENS_KEY} in ${REF_DAB_ENS_FILE}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    fi

    process_dab_channel_results "${CH}" "${CH_RAW}" "${DTFFIC}" "${KEEP_RAW_FILE}"
  else
    "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
    process_dab_channel_results "${CH}" "" "${DTFFIC}"
  fi
done

if [ -d /sys/class/thermal/thermal_zone0 ]; then
  echo -e "$(date -u "+%Y-%m-%dT%T Z"): Temperature at scanDAB.sh after dab-rtlsdr: $(cat /sys/class/thermal/thermal_zone*/temp | tr '\n' ' ')" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  echo "$(date -u +%s), $(cat /sys/class/thermal/thermal_zone*/temp | tr '\n' ' ')" >>${FMLIST_SCAN_RAM_DIR}/cputemp.csv
fi

TEND="$(date -u +%s)"
TDUR=$[ $TEND - $TBEG ]
DTF="$(date -u "+%Y-%m-%dT%T.%N Z")"
echo "DAB scan finished at ${DTF}"
echo "DAB scan finished at ${DTF}" >>${rec_path}/scan_duration.txt
echo "DAB scan duration ${TDUR} sec"
echo "DAB scan duration ${TDUR} sec" >>${rec_path}/scan_duration.txt
echo "DAB scan found ${NUMFOUND} stations"
echo "DAB scan found ${NUMFOUND} stations" >>${rec_path}/scan_duration.txt
if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
  echo "DAB scan finished at ${DTF}. Duration ${TDUR} sec." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
fi
if [ ${FMLIST_SCAN_RASPI} -ne 0 ] && [ ${FMLIST_SCAN_PWM_FEEDBACK} -ne 0 ]; then
  scanToneFeedback.sh dab ${NUMFOUND}
fi

