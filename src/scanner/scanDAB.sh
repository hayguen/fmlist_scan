#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

if [ -d "$HOME/.local/lib" ]; then
  case ":${LD_LIBRARY_PATH}:" in
    *":$HOME/.local/lib:"*) ;;
    *) export LD_LIBRARY_PATH="$HOME/.local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ;;
  esac
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
      -Q)
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
        # strip -D (no detailed audio in discovery pass)
        ;;
      -O)
        # strip -O <arg>: prevents raw-IQ dump to stdout which would corrupt the log file
        i=$[ $i + 1 ]
        ;;
      *)
        out+=("${tok}")
        ;;
    esac
    i=$[ $i + 1 ]
  done
  printf '%s\n' "${out[*]}"
}

function runDabRaw() {
  local STDOUT_FILE="$1"
  local STDERR_FILE="$2"
  shift 2

  timeout -s SIGTERM -k 5 "${FMLIST_SCAN_DAB_RAW_TIMEOUT_SEC}" "${DAB_RAW_BIN}" "$@" 1>"${STDOUT_FILE}" 2>"${STDERR_FILE}"
  local RAW_RC=$?
  if [ ${RAW_RC} -eq 124 ]; then
    echo "$(date -u "+%Y-%m-%dT%T.%N Z"): dab-raw timed out after ${FMLIST_SCAN_DAB_RAW_TIMEOUT_SEC}s; continuing with recovery" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  fi
  return ${RAW_RC}
}

function tuneDabOptForUnknownEnsembleRetry() {
  local in="$1"
  local out=""

  out=$( echo " ${in} " | sed -E 's/[[:space:]]-E[[:space:]]+[0-9]+/ -E 0/g; s/[[:space:]]-W[[:space:]]+[0-9]+/ -W 9000/g; s/[[:space:]]-A[[:space:]]+[0-9]+/ -A 6000/g; s/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/ /g' )

  if [[ " ${out} " != *" -E "* ]]; then
    out="${out} -E 0"
  fi
  if [[ " ${out} " != *" -W "* ]]; then
    out="${out} -W 9000"
  fi
  if [[ " ${out} " != *" -A "* ]]; then
    out="${out} -A 6000"
  fi
  if [[ " ${out} " != *" -c "* ]]; then
    out="${out} -c"
  fi

  printf '%s\n' "${out}"
}

function countCsvUniqueServiceSids() {
  local LOGFILE="$1"
  if [ -z "${LOGFILE}" ] || [ ! -f "${LOGFILE}" ]; then
    echo 0
    return 0
  fi
  awk -F',' '
    ($2=="CSV_AUDIO" || $2=="CSV_PACKET") {
      sid=$6;
      gsub(/"/, "", sid);
      sid=tolower(sid);
      if (sid=="" || sid=="0x0000") next;
      seen[sid]=1;
    }
    END {
      n=0;
      for (k in seen) n++;
      print n+0;
    }
  ' "${LOGFILE}" 2>/dev/null
}

function rerunMissingServiceDetailsWithD() {
  local CH="$1"
  local RAWFILE="$2"
  local BASE_OPTS="$3"
  local EXPECTED_MIN_SIDS="$4"
  local MAIN_LOG="${rec_path}/DAB_${CH}.log"
  local MAIN_ERR="${rec_path}/DAB_${CH}_stderr.log"
  local TMP_BASE="${rec_path}/.DAB_${CH}_missing_sid_${RANDOM}_$$"
  local EXPECTED_FILE="${TMP_BASE}_expected_sids.txt"
  local PRESENT_FILE="${TMP_BASE}_present_sids.txt"
  local MISSING_FILE="${TMP_BASE}_missing_sids.txt"
  local SID_LOG="${TMP_BASE}_work.log"
  local SID_ERR="${TMP_BASE}_work_stderr.log"
  local SID_ROWS="${TMP_BASE}_work_rows.csv"

  if [ -z "${CH}" ] || [ -z "${RAWFILE}" ] || [ ! -f "${RAWFILE}" ] || [ ! -f "${MAIN_LOG}" ] || [ ! -f "${MAIN_ERR}" ]; then
    return 0
  fi

  grep "^programnameHandler:.* is part of the ensemble" "${MAIN_ERR}" 2>/dev/null \
    | sed -n "s/.*(SId \([0-9A-Fa-f]\+\)).*/\1/p" \
    | tr '[:lower:]' '[:upper:]' \
    | sort -u >"${EXPECTED_FILE}" || true

  # ABRA CSV path may not emit legacy programnameHandler lines on stderr.
  # Fall back to CSV_SERVICE/CSV_AUDIO/CSV_PACKET rows to build expected SID list.
  if [ ! -s "${EXPECTED_FILE}" ]; then
    awk -F',' '
      $1=="CSV_SERVICE" {
        sid=$2; gsub(/"/, "", sid); sub(/^0[xX]/, "", sid);
        if (sid!="") print toupper(sid);
      }
      $2=="CSV_SERVICE" {
        sid=$3; gsub(/"/, "", sid); sub(/^0[xX]/, "", sid);
        if (sid!="") print toupper(sid);
      }
      ($1=="CSV_AUDIO" || $1=="CSV_PACKET") {
        sid=$5; gsub(/"/, "", sid); sub(/^0[xX]/, "", sid);
        if (sid!="") print toupper(sid);
      }
      ($2=="CSV_AUDIO" || $2=="CSV_PACKET") {
        sid=$6; gsub(/"/, "", sid); sub(/^0[xX]/, "", sid);
        if (sid!="") print toupper(sid);
      }
    ' "${MAIN_LOG}" 2>/dev/null | sort -u >"${EXPECTED_FILE}" || true
  fi

  grep ",CSV_AUDIO,\|,CSV_PACKET," "${MAIN_LOG}" 2>/dev/null \
    | awk -F',' '
      {
        kind=$2;
        sid=$6;
        gsub(/"/, "", sid);
        sub(/^0[xX]/, "", sid);
        if (sid == "") next;

        if (kind=="CSV_PACKET") {
          print toupper(sid);
          next;
        }

        if (kind=="CSV_AUDIO") {
          if ($0 ~ /255 unknown( \(Non-NA\))?/) {
            next;
          }
          codec=$15;
          gsub(/^"|"$/, "", codec);
          if (codec != "DAB+/audio" && codec != "DAB/audio") {
            print toupper(sid);
          }
        }
      }
    ' \
    | sort -u >"${PRESENT_FILE}" || true

  comm -23 "${EXPECTED_FILE}" "${PRESENT_FILE}" >"${MISSING_FILE}" || true

  local MISSING_COUNT
  MISSING_COUNT=$(wc -l <"${MISSING_FILE}" 2>/dev/null || echo 0)
  if [ -z "${MISSING_COUNT}" ]; then MISSING_COUNT=0; fi

  # FIC too weak: no programnameHandler lines → EXPECTED_FILE empty, MISSING_COUNT=0.
  # Synthesize N anonymous too-weak-signal rows when reference count is known.
  if [ ${MISSING_COUNT} -le 0 ]; then
    local _EA_AUDIO
    _EA_AUDIO=$(awk -F',' '$2=="CSV_AUDIO"{found++} END{print found+0}' "${MAIN_LOG}" 2>/dev/null)
    if [ "${_EA_AUDIO:-0}" -eq 0 ]; then
      local _EA_EID _EA_NAME _EA_NAME_SAFE _EA_NUM_SIDS
      _EA_EID=$(awk -F',' '$2=="CSV_ENSEMBLE"{print tolower($4);exit}' "${MAIN_LOG}" 2>/dev/null)
      _EA_NAME=$(awk -F',' '$2=="CSV_ENSEMBLE"{n=$5;gsub(/^"|"$/,"",n);print n;exit}' "${MAIN_LOG}" 2>/dev/null)
      [ -z "${_EA_EID}" ] && _EA_EID="0x0000"
      [ -z "${_EA_NAME}" ] && _EA_NAME=$(grep "ensemblenameHandler:" "${MAIN_ERR}" 2>/dev/null | head -n1 | sed -n "s/.*ensemblenameHandler: '\([^']*\)'.*/\1/p")
      [ -z "${_EA_NAME}" ] && _EA_NAME="unknown ensemble"
      _EA_NAME_SAFE=$(echo "${_EA_NAME}" | tr '"' "'")
      # use passed EXPECTED_MIN_SIDS; if 0, fall back to 1 (ensemble known but no service count)
      _EA_NUM_SIDS="${EXPECTED_MIN_SIDS:-0}"
      if [ "${_EA_NUM_SIDS}" -eq 0 ] 2>/dev/null; then
        _EA_NUM_SIDS=1
      fi
      if [ "${_EA_EID}" != "0x0000" ] && [ "$(echo "${_EA_NAME_SAFE}" | tr '[:upper:]' '[:lower:]')" != "unknown ensemble" ] && [ "${_EA_NUM_SIDS}" -ge 1 ] 2>/dev/null; then
        echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: FIC too weak (no service names); synthesizing ${_EA_NUM_SIDS} anonymous too-weak-signal rows for ensemble '${_EA_NAME_SAFE}' (${_EA_EID})" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
        local _i
        for _i in $(seq 1 "${_EA_NUM_SIDS}"); do
          echo "$(date -u +%s),CSV_AUDIO,\"${CH}\",${_EA_EID},\"${_EA_NAME_SAFE}\",0x0000,\"unknown service\",0,0,\"\",0,\"\",0,0,\"DAB+/too weak signal\",0x0,0x0,\"\",0,\"\",0,\"\",0,0,\"\",\"\",\"\"" >>"${MAIN_LOG}"
        done
      fi
    fi
    rm -f "${EXPECTED_FILE}" "${PRESENT_FILE}" "${MISSING_FILE}" "${SID_LOG}" "${SID_ERR}" "${SID_ROWS}" 2>/dev/null || true
    return 0
  fi

  local EXPECTED_COUNT
  EXPECTED_COUNT=$(wc -l <"${EXPECTED_FILE}" 2>/dev/null || echo 0)
  if [ -z "${EXPECTED_COUNT}" ]; then EXPECTED_COUNT=0; fi
  if [ -n "${EXPECTED_MIN_SIDS}" ] && [ "${EXPECTED_MIN_SIDS}" -gt 0 ] 2>/dev/null; then
    if [ ${EXPECTED_COUNT} -lt ${EXPECTED_MIN_SIDS} ]; then
      EXPECTED_COUNT=${EXPECTED_MIN_SIDS}
    fi
  fi

  # If no SID has real decoded audio (all placeholder DAB+/audio) and 2+ SIDs are
  # missing, per-SID retries on the same weak-signal clip cannot succeed.
  # Replace all placeholders with "too weak signal" and synthesize rows for
  # completely absent SIDs using service names already decoded from FIC.
  # If no audio service decoded with a real codec, signal is too weak for per-SID retries.
  local _PRESENT_AUDIO_COUNT
  _PRESENT_AUDIO_COUNT=$(awk -F',' '
    $2=="CSV_AUDIO" { codec=$15; gsub(/^"|"$/, "", codec)
      if (codec != "DAB+/audio" && codec != "DAB/audio") real++
    }
    END { print real+0 }
  ' "${MAIN_LOG}" 2>/dev/null)

  local _REAL_DECODED_AUDIO_COUNT
  _REAL_DECODED_AUDIO_COUNT=$(awk -F',' '
    $2=="CSV_AUDIO" {
      codec=$15; gsub(/^"|"$/, "", codec)
      low=tolower(codec)
      if (codec=="DAB+/audio" || codec=="DAB/audio") next
      if (index(low, "too weak")>0) next
      if (index(low, "no audio")>0) next
      real++
    }
    END { print real+0 }
  ' "${MAIN_LOG}" 2>/dev/null)
  if [ "${_PRESENT_AUDIO_COUNT:-0}" -eq 0 ] && [ "${MISSING_COUNT}" -ge 2 ] 2>/dev/null; then
    echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: signal too weak: no real audio for any of ${EXPECTED_COUNT} expected service(s); marking all as too weak signal, skipping per-SID retries" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    awk -F',' 'OFS="," {
      if ($2=="CSV_AUDIO") {
        codec=$15; gsub(/^"|"$/, "", codec);
        if (codec=="DAB+/audio") $15="\"DAB+/too weak signal\""
        else if (codec=="DAB/audio") $15="\"DAB/too weak signal\""
      }
      print
    }' "${MAIN_LOG}" >"${MAIN_LOG}.tmp" && mv "${MAIN_LOG}.tmp" "${MAIN_LOG}"
    local _TW_ENS_EID _TW_ENS_NAME _TW_ENS_NAME_SAFE
    _TW_ENS_EID=$(awk -F',' '$2=="CSV_ENSEMBLE" { print tolower($4); exit }' "${MAIN_LOG}" 2>/dev/null)
    _TW_ENS_NAME=$(awk -F',' '$2=="CSV_ENSEMBLE" { n=$5; gsub(/^"|"$/, "", n); print n; exit }' "${MAIN_LOG}" 2>/dev/null)
    if [ -z "${_TW_ENS_EID}" ]; then _TW_ENS_EID="0x0000"; fi
    if [ -z "${_TW_ENS_NAME}" ] || [ "$(echo "${_TW_ENS_NAME}" | tr '[:upper:]' '[:lower:]')" = "unknown ensemble" ]; then
      _TW_ENS_NAME=$(grep "ensemblenameHandler:" "${MAIN_ERR}" 2>/dev/null | head -n1 \
        | sed -n "s/.*ensemblenameHandler: '\([^']*\)'.*/\1/p")
      [ -z "${_TW_ENS_NAME}" ] && _TW_ENS_NAME="unknown ensemble"
    fi
    local _MISSING_COUNT
    _MISSING_COUNT=$(wc -l <"${MISSING_FILE}" 2>/dev/null | tr -d ' ' || echo 0)
    if [ "${_MISSING_COUNT}" -eq 0 ]; then
      echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: no service names decoded from FIC (signal too weak); ensemble '${_TW_ENS_NAME}' (${_TW_ENS_EID}) detected but no audio rows to synthesize" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    fi
    _TW_ENS_NAME_SAFE=$(echo "${_TW_ENS_NAME}" | tr '"' "'")
    while IFS= read -r SID_HEX; do
      [ -z "${SID_HEX}" ] && continue
      local _TW_SID_L _TW_HAS_ROW _TW_SID_NAME _TW_SID_NAME_SAFE _TW_ROW
      _TW_SID_L=$(echo "${SID_HEX}" | tr '[:upper:]' '[:lower:]')
      _TW_HAS_ROW=$(awk -F',' -v s="0x${_TW_SID_L}" \
        '$2=="CSV_AUDIO" { sid=$6; gsub(/"/, "", sid); if (tolower(sid)==s) { f=1; exit } } END { print f+0 }' \
        "${MAIN_LOG}" 2>/dev/null)
      [ "${_TW_HAS_ROW:-0}" -gt 0 ] && continue
      _TW_SID_NAME=$(grep "^programnameHandler:.* is part of the ensemble" "${MAIN_ERR}" 2>/dev/null \
        | sed -n "s/^programnameHandler: '\(.*\)' \/ '.*' (SId \([0-9A-Fa-f]\+\)) is part of the ensemble$/\2|\1/p" \
        | awk -F'|' -v sid="${SID_HEX}" 'toupper($1)==toupper(sid) { print $2; exit }')
      [ -z "${_TW_SID_NAME}" ] && _TW_SID_NAME="SID 0x${_TW_SID_L}"
      _TW_SID_NAME_SAFE=$(echo "${_TW_SID_NAME}" | tr '"' "'")
      if [ "$(echo "${_TW_ENS_NAME_SAFE}" | tr '[:upper:]' '[:lower:]')" != "unknown ensemble" ] && \
         [ "${_TW_ENS_EID}" != "0x0000" ] && [ "${_TW_ENS_EID}" != "0xffffffff" ]; then
        _TW_ROW="$(date -u +%s),CSV_AUDIO,\"${CH}\",${_TW_ENS_EID},\"${_TW_ENS_NAME_SAFE}\",0x${_TW_SID_L},\"${_TW_SID_NAME_SAFE}\",0,0,\"\",0,\"\",0,0,\"DAB+/too weak signal\",0x0,0x0,\"\",0,\"\",0,\"\",0,0,\"\",\"\",\"\""
        echo "${_TW_ROW}" >>"${MAIN_LOG}"
        echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: synthesized too-weak-signal row for SID 0x${_TW_SID_L} ('${_TW_SID_NAME_SAFE}')" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      fi
    done <"${MISSING_FILE}"
    rm -f "${EXPECTED_FILE}" "${PRESENT_FILE}" "${MISSING_FILE}" "${SID_LOG}" "${SID_ERR}" "${SID_ROWS}" 2>/dev/null || true
    return 0
  fi

  local RERUN_OPTS="${BASE_OPTS}"
  if [[ " ${RERUN_OPTS} " != *" -D "* ]]; then
    RERUN_OPTS="${RERUN_OPTS} -D"
  fi
  # Per-SID retries: strip -X/-Y (no rewind for single-service analysis) and cap -W/-A
  # so dab-raw exits after 2 s post-ensemble instead of scanning the whole clip.
  local _RAWBYTES _FULL_W_MS _SID_W_MS
  _RAWBYTES=$(wc -c <"${RAWFILE}" 2>/dev/null || echo 0)
  if [ "${_RAWBYTES:-0}" -gt 2048 ] 2>/dev/null; then
    _FULL_W_MS=$(( _RAWBYTES / 2048 ))
    _SID_W_MS="${FMLIST_SCAN_DAB_SID_RETRY_W_MS:-8000}"
    if [ "${_SID_W_MS}" -gt "${_FULL_W_MS}" ] 2>/dev/null; then
      _SID_W_MS="${_FULL_W_MS}"
    fi
    RERUN_OPTS=$(echo " ${RERUN_OPTS} " | \
      sed -E "s/ -W [0-9]+ / -W ${_SID_W_MS} /g; s/ -A [0-9-]+ / -A -1 /g" | \
      sed -E "s/ -X / /g; s/ -Y / /g" | \
      sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
  fi

  echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: missing/incomplete ${MISSING_COUNT}/${EXPECTED_COUNT} service SID(s) or unresolved PTY; rerunning with strict -D -S for real values" >>${FMLIST_SCAN_RAM_DIR}/scanner.log

  while IFS= read -r SID_HEX; do
    [ -z "${SID_HEX}" ] && continue
    local SID_HEX_LOWER
    SID_HEX_LOWER=$(echo "${SID_HEX}" | tr '[:upper:]' '[:lower:]')

    echo "${DAB_RAW_BIN} -F ${RAWFILE} ${RERUN_OPTS} -S ${SID_HEX}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    runDabRaw "${SID_LOG}" "${SID_ERR}" -F "${RAWFILE}" ${RERUN_OPTS} -S "${SID_HEX}"
    sed -i -E "s/(,CSV_(AUDIO|ENSEMBLE|GPSCOOR|PACKET),\")[^\"]*(\")/\1${CH}\3/g" "${SID_LOG}"

    awk -F',' -v sidWanted="0x${SID_HEX_LOWER}" '
      ($2=="CSV_AUDIO" || $2=="CSV_PACKET") {
        sid=$6;
        gsub(/"/, "", sid);
        sid=tolower(sid);
        if (sid == sidWanted) print $0;
      }
    ' "${SID_LOG}" >"${SID_ROWS}" || true

    if [ -s "${SID_ROWS}" ]; then
      # Replace placeholder generic codec rows for this SID with recovered rows.
      awk -F',' -v sidWanted="0x${SID_HEX_LOWER}" '
        {
          if ($2=="CSV_AUDIO") {
            sid=$6; gsub(/"/, "", sid); sid=tolower(sid);
            codec=$15; gsub(/^"|"$/, "", codec);
            if (sid==sidWanted && (codec=="DAB+/audio" || codec=="DAB/audio")) next;
          }
          print $0;
        }
      ' "${MAIN_LOG}" >"${MAIN_LOG}.tmp" && mv "${MAIN_LOG}.tmp" "${MAIN_LOG}"

      while IFS= read -r ROW; do
        [ -z "${ROW}" ] && continue
        if ! grep -Fqx "${ROW}" "${MAIN_LOG}" 2>/dev/null; then
          echo "${ROW}" >>"${MAIN_LOG}"
        fi
      done <"${SID_ROWS}"
      local _REC_TYPE
      _REC_TYPE=$(awk -F',' '
        $2=="CSV_PACKET" { print "packet service"; exit }
        $2=="CSV_AUDIO"  { codec=$15; gsub(/^"|"$/, "", codec); print codec; exit }
      ' "${SID_ROWS}" 2>/dev/null)
      # If retry also returned only a placeholder, use _PRESENT_AUDIO_COUNT to decide:
      # if other audio services decoded fine the issue is service-specific (no audio),
      # if nothing decoded on this channel it is a signal problem (too weak signal).
      echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: SID 0x${SID_HEX_LOWER}: retry returned _REC_TYPE='${_REC_TYPE}', _PRESENT_AUDIO_COUNT=${_PRESENT_AUDIO_COUNT:-0}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      if [ "${_REC_TYPE}" = "DAB+/audio" ] || [ "${_REC_TYPE}" = "DAB/audio" ]; then
        local _RETRY_PH_CODEC
        if [ "${_REAL_DECODED_AUDIO_COUNT:-0}" -gt 0 ] 2>/dev/null; then
          _RETRY_PH_CODEC="DAB+/too weak or no audio"
        else
          _RETRY_PH_CODEC="DAB+/too weak signal"
        fi
        awk -F',' -v OFS=',' -v s="0x${SID_HEX_LOWER}" -v c="${_RETRY_PH_CODEC}" '
          $2=="CSV_AUDIO" { sid=$6; gsub(/"/, "", sid); sid=tolower(sid)
            if (sid==s) { codec=$15; gsub(/^"|"$/, "", codec)
              if (codec=="DAB+/audio" || codec=="DAB/audio") { $15="\"" c "\""; found++ }
            }
          }
          { print }
          END { if (found) print "MARKED " found " row(s) for " s " as " c > "/dev/stderr" }
        ' "${MAIN_LOG}" >"${MAIN_LOG}.tmp" && mv "${MAIN_LOG}.tmp" "${MAIN_LOG}"
        echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: SID 0x${SID_HEX_LOWER}: retry returned placeholder, marked as ${_RETRY_PH_CODEC}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      elif [ "${_REC_TYPE}" = "DAB+/too weak audio" ] || [ "${_REC_TYPE}" = "DAB/too weak audio" ] || [ "${_REC_TYPE}" = "DAB+/too weak or no audio" ] || [ "${_REC_TYPE}" = "DAB/too weak or no audio" ]; then
        awk -F',' -v OFS=',' -v s="0x${SID_HEX_LOWER}" '
          $2=="CSV_AUDIO" {
            sid=$6; gsub(/"/, "", sid); sid=tolower(sid)
            if (sid==s) {
              codec=$15; gsub(/^"|"$/, "", codec)
              if (codec=="DAB+/too weak audio" || codec=="DAB+/no audio" || codec=="DAB+/too weak or no audio") {
                $15="\"DAB+/too weak or no audio\""
              } else if (codec=="DAB/too weak audio" || codec=="DAB/no audio" || codec=="DAB/too weak or no audio") {
                $15="\"DAB/too weak or no audio\""
              }
            }
          }
          { print }
        ' "${MAIN_LOG}" >"${MAIN_LOG}.tmp" && mv "${MAIN_LOG}.tmp" "${MAIN_LOG}"
        echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: SID 0x${SID_HEX_LOWER}: normalized unresolved-audio status" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      else
        # Retry returned a real codec.
        echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: recovered SID 0x${SID_HEX_LOWER}: ${_REC_TYPE:-no audio}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      fi
    else
      # strict -D -S returned no rows.
      # Only apply "too weak signal" when the per-SID retry stderr explicitly says so.
      # If dab-raw produced no audio rows but did not say "too weak", the failure is
      # simply that the 5-second clip didn't contain decodable audio for this subchannel
      # (even though other services in the same multiplex decoded fine).  Mislabeling
      # those as "too weak signal" is a false positive.  Keep the existing "DAB+/audio"
      # placeholder instead; skip synthesis entirely when no placeholder exists.
      local _SID_RETRY_TOO_WEAK="0"
      if grep -qi "too weak" "${SID_ERR}" 2>/dev/null; then
        _SID_RETRY_TOO_WEAK="1"
      fi

      local _FOUND_PLACEHOLDER
      _FOUND_PLACEHOLDER=$(awk -F',' -v sidWanted="0x${SID_HEX_LOWER}" '
        $2=="CSV_AUDIO" { sid=$6; gsub(/"/, "", sid); sid=tolower(sid);
          if (sid==sidWanted) { codec=$15; gsub(/^"|"$/, "", codec);
            if (codec=="DAB+/audio" || codec=="DAB/audio") found++ }
        }
        END { print found+0 }
      ' "${MAIN_LOG}" 2>/dev/null)

      if [ "${_SID_RETRY_TOO_WEAK}" != "1" ]; then
        # Decoder did not confirm weak signal.
        # If other services decode fine on this multiplex, mark the unresolved SID as too weak or no audio.
        if [ "${_FOUND_PLACEHOLDER:-0}" -gt 0 ] 2>/dev/null && [ "${_REAL_DECODED_AUDIO_COUNT:-0}" -gt 0 ] 2>/dev/null; then
          awk -F',' -v sidWanted="0x${SID_HEX_LOWER}" '
            $2=="CSV_AUDIO" {
              sid=$6; gsub(/"/, "", sid); sid=tolower(sid);
              if (sid==sidWanted) {
                codec=$15; gsub(/^"|"$/, "", codec);
                if (codec=="DAB+/audio") {
                  old = "\"DAB+/audio\""
                  new = "\"DAB+/too weak or no audio\""
                  n = index($0, old)
                  if (n > 0) $0 = substr($0, 1, n-1) new substr($0, n+length(old))
                } else if (codec=="DAB/audio") {
                  old = "\"DAB/audio\""
                  new = "\"DAB/too weak or no audio\""
                  n = index($0, old)
                  if (n > 0) $0 = substr($0, 1, n-1) new substr($0, n+length(old))
                }
              }
            }
            { print }
          ' "${MAIN_LOG}" >"${MAIN_LOG}.tmp" && mv "${MAIN_LOG}.tmp" "${MAIN_LOG}"
          echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: marked SID 0x${SID_HEX_LOWER} as too weak or no audio (other services decoded; no weak-signal indication)" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
        elif [ "${_FOUND_PLACEHOLDER:-0}" -gt 0 ] 2>/dev/null; then
          echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: keeping 'DAB+/audio' placeholder for SID 0x${SID_HEX_LOWER} (no weak-signal indication from decoder; no other decoded audio services)" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
        else
          echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: skipping fallback for SID 0x${SID_HEX_LOWER} (no audio in clip; no weak-signal indication from decoder)" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
        fi
      elif [ "${_FOUND_PLACEHOLDER:-0}" -gt 0 ] 2>/dev/null; then
        awk -F',' -v sidWanted="0x${SID_HEX_LOWER}" '
          $2=="CSV_AUDIO" {
            sid=$6; gsub(/"/, "", sid); sid=tolower(sid);
            if (sid==sidWanted) {
              codec=$15; gsub(/^"|"$/, "", codec);
              if (codec=="DAB+/audio" || codec=="DAB/audio") {
                old = "\"" codec "\""
                new = (codec=="DAB+/audio") ? "\"DAB+/too weak signal\"" : "\"DAB/too weak signal\""
                n = index($0, old)
                if (n > 0) $0 = substr($0, 1, n-1) new substr($0, n+length(old))
              }
            }
          }
          { print }
        ' "${MAIN_LOG}" >"${MAIN_LOG}.tmp" && mv "${MAIN_LOG}.tmp" "${MAIN_LOG}"
        echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: updated placeholder to 'too weak signal' for SID 0x${SID_HEX_LOWER} (strict -D returned no rows; FIC values preserved)" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      else
        # No placeholder row found: synthesize a minimal fallback with "too weak signal".
        local ENS_EID
        local ENS_NAME
        local SID_NAME
        local ENS_NAME_SAFE
        local SID_NAME_SAFE
        local FALLBACK_ROW

        ENS_EID=$(awk -F',' '$2=="CSV_ENSEMBLE" { print tolower($4); exit }' "${MAIN_LOG}" 2>/dev/null)
        ENS_NAME=$(awk -F',' '$2=="CSV_ENSEMBLE" { print $5; exit }' "${MAIN_LOG}" 2>/dev/null | sed 's/^"//; s/"$//')
        if [ -z "${ENS_EID}" ]; then ENS_EID="0x0000"; fi
        if [ -z "${ENS_NAME}" ] || [ "$(echo "${ENS_NAME}" | tr '[:upper:]' '[:lower:]')" = "unknown ensemble" ]; then
          ENS_NAME=$(grep "ensemblenameHandler:" "${MAIN_ERR}" 2>/dev/null | head -n1 \
            | sed -n "s/.*ensemblenameHandler: '\([^']*\)'.*/\1/p")
          [ -z "${ENS_NAME}" ] && ENS_NAME="unknown ensemble"
        fi
        # Prefer known name from reference over "unknown ensemble"
        if [ "$(echo "${ENS_NAME}" | tr '[:upper:]' '[:lower:]')" = "unknown ensemble" ] && \
           [ "${ENS_EID}" != "0x0000" ] && [ "${ENS_EID}" != "0xffffffff" ]; then
          _KNOWN=$(getKnownEnsembleNameByEid "${ENS_EID}" 2>/dev/null)
          [ -n "${_KNOWN}" ] && ENS_NAME="${_KNOWN}"
        fi

        SID_NAME=$(grep "^programnameHandler:.* is part of the ensemble" "${MAIN_ERR}" 2>/dev/null \
          | sed -n "s/^programnameHandler: '\(.*\)' \/ '.*' (SId \([0-9A-Fa-f]\+\)) is part of the ensemble$/\2|\1/p" \
          | awk -F'|' -v sid="${SID_HEX}" 'toupper($1)==toupper(sid) { print $2; exit }')
        if [ -z "${SID_NAME}" ]; then SID_NAME="SID 0x${SID_HEX_LOWER}"; fi

        ENS_NAME_SAFE=$(echo "${ENS_NAME}" | tr '"' "'")
        SID_NAME_SAFE=$(echo "${SID_NAME}" | tr '"' "'")

        # Skip fallback row when ensemble identity is still unknown — useless noise
        if [ "$(echo "${ENS_NAME_SAFE}" | tr '[:upper:]' '[:lower:]')" = "unknown ensemble" ] || \
           [ "${ENS_EID}" = "0x0000" ] || [ "${ENS_EID}" = "0xffffffff" ]; then
          echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: skipping fallback row for SID 0x${SID_HEX_LOWER}: ensemble identity unknown (EId=${ENS_EID})" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
        else
          FALLBACK_ROW="$(date -u +%s),CSV_AUDIO,\"${CH}\",${ENS_EID},\"${ENS_NAME_SAFE}\",0x${SID_HEX_LOWER},\"${SID_NAME_SAFE}\",0,0,\"\",0,\"\",0,0,\"DAB+/too weak signal\",0x0,0x0,\"\",0,\"\",0,\"\",0,0,\"\",\"\",\"\""
          awk -F',' -v sidWanted="0x${SID_HEX_LOWER}" '
            { if ($2=="CSV_AUDIO") { sid=$6; gsub(/"/, "", sid); sid=tolower(sid);
                if (sid==sidWanted) next }
              print }
          ' "${MAIN_LOG}" >"${MAIN_LOG}.tmp" && mv "${MAIN_LOG}.tmp" "${MAIN_LOG}"
          echo "${FALLBACK_ROW}" >>"${MAIN_LOG}"
          echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: synthesized fallback row (DAB+/too weak signal) for SID 0x${SID_HEX_LOWER} (strict -D returned no rows; no placeholder found)" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
        fi
      fi
    fi
  done <"${MISSING_FILE}"

  rm -f "${EXPECTED_FILE}" "${PRESENT_FILE}" "${MISSING_FILE}" "${SID_LOG}" "${SID_ERR}" "${SID_ROWS}" 2>/dev/null || true
}

function normalizeServiceSpecificTooWeakAudio() {
  local CH="$1"
  local MAIN_LOG="$2"

  if [ -z "${CH}" ] || [ -z "${MAIN_LOG}" ] || [ ! -f "${MAIN_LOG}" ]; then
    return 0
  fi

  local REAL_AUDIO_COUNT
  REAL_AUDIO_COUNT=$(awk -F',' '
    $2=="CSV_AUDIO" {
      codec=$15; gsub(/^"|"$/, "", codec)
      low=tolower(codec)
      if (codec=="DAB+/audio" || codec=="DAB/audio") next
      if (codec=="DAB+/AAC-LC Mono 32kHz" || codec=="DAB/AAC-LC Mono 32kHz") next
      if (index(low, "too weak")>0) next
      if (index(low, "no audio")>0) next
      real++
    }
    END { print real+0 }
  ' "${MAIN_LOG}" 2>/dev/null)

  local CHANGED_COUNT
  CHANGED_COUNT=$(awk -F',' '
    $2=="CSV_AUDIO" {
      codec=$15; gsub(/^"|"$/, "", codec)
      if (codec=="DAB+/too weak audio" || codec=="DAB/too weak audio" ||
          codec=="DAB+/audio" || codec=="DAB/audio" ||
          codec=="DAB+/no audio" || codec=="DAB/no audio" ||
          codec=="DAB+/AAC-LC Mono 32kHz" || codec=="DAB/AAC-LC Mono 32kHz") n++
    }
    END { print n+0 }
  ' "${MAIN_LOG}" 2>/dev/null)

  if [ "${CHANGED_COUNT:-0}" -le 0 ] 2>/dev/null; then
    return 0
  fi

  awk -F',' -v OFS=',' '
    $2=="CSV_AUDIO" {
      codec=$15; gsub(/^"|"$/, "", codec)
      if (codec=="DAB+/too weak audio" || codec=="DAB+/audio" ||
          codec=="DAB+/no audio" || codec=="DAB+/AAC-LC Mono 32kHz") {
        $15="\"DAB+/too weak or no audio\""
      } else if (codec=="DAB/too weak audio" || codec=="DAB/audio" ||
                 codec=="DAB/no audio" || codec=="DAB/AAC-LC Mono 32kHz") {
        $15="\"DAB/too weak or no audio\""
      }
    }
    { print }
  ' "${MAIN_LOG}" >"${MAIN_LOG}.tmp" && mv "${MAIN_LOG}.tmp" "${MAIN_LOG}"

  echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: normalized ${CHANGED_COUNT} unresolved service row(s) to too-weak-or-no-audio (channel has ${REAL_AUDIO_COUNT} real decoded audio service(s))" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
}

function synthesizeWeakAudioRowsFromProgramList() {
  local CH="$1"
  local MAIN_LOG="$2"
  local MAIN_ERR="$3"

  if [ -z "${CH}" ] || [ -z "${MAIN_LOG}" ] || [ -z "${MAIN_ERR}" ] || [ ! -f "${MAIN_LOG}" ] || [ ! -f "${MAIN_ERR}" ]; then
    return 0
  fi

  local AUDIO_CNT
  AUDIO_CNT=$(awk -F',' '$2=="CSV_AUDIO"{n++} END{print n+0}' "${MAIN_LOG}" 2>/dev/null)
  if [ "${AUDIO_CNT:-0}" -gt 0 ] 2>/dev/null; then
    return 0
  fi
  local PACKET_CNT
  PACKET_CNT=$(awk -F',' '$2=="CSV_PACKET"{n++} END{print n+0}' "${MAIN_LOG}" 2>/dev/null)

  local ENS_EID ENS_NAME ENS_NAME_SAFE
  ENS_EID=$(awk -F',' '$2=="CSV_ENSEMBLE" { print tolower($4); exit }' "${MAIN_LOG}" 2>/dev/null)
  ENS_NAME=$(awk -F',' '$2=="CSV_ENSEMBLE" { n=$5; gsub(/^"|"$/, "", n); print n; exit }' "${MAIN_LOG}" 2>/dev/null)
  if [ -z "${ENS_EID}" ] || [ -z "${ENS_NAME}" ]; then
    return 0
  fi
  if [ "${ENS_EID}" = "0x0000" ] || [ "${ENS_EID}" = "0xffffffff" ] || [ "$(echo "${ENS_NAME}" | tr '[:upper:]' '[:lower:]')" = "unknown ensemble" ]; then
    return 0
  fi
  ENS_NAME_SAFE=$(echo "${ENS_NAME}" | tr '"' "'")

  local TMP_SIDS
  TMP_SIDS="${MAIN_LOG}.weak_sidlist.$$.tmp"
  grep "^programnameHandler:.* is part of the ensemble" "${MAIN_ERR}" 2>/dev/null \
    | sed -n "s/^programnameHandler: '\(.*\)' \/ '.*' (SId \([0-9A-Fa-f]\+\)) is part of the ensemble$/\2|\1/p" \
    | awk -F'|' '{ sid=toupper($1); name=$2; gsub(/[[:space:]]+$/, "", name); print sid "|" name }' \
    | sort -u >"${TMP_SIDS}" || true

  local SID_CNT
  SID_CNT=$(wc -l <"${TMP_SIDS}" 2>/dev/null || echo 0)
  if [ "${SID_CNT:-0}" -le 0 ] 2>/dev/null; then
    if [ "${PACKET_CNT:-0}" -eq 0 ] 2>/dev/null; then
      echo "$(date -u +%s),CSV_AUDIO,\"${CH}\",${ENS_EID},\"${ENS_NAME_SAFE}\",0x0000,\"unknown service\",0,0,\"\",0,\"\",0,0,\"DAB+/too weak signal\",0x0,0x0,\"\",0,\"\",0,\"\",0,0,\"\",\"\",\"\"" >>"${MAIN_LOG}"
      echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: synthesized anonymous weak-signal row (ensemble known, but no service names and no audio/packet rows)" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    fi
    rm -f "${TMP_SIDS}" 2>/dev/null || true
    return 0
  fi

  while IFS='|' read -r SID_HEX SID_NAME; do
    [ -z "${SID_HEX}" ] && continue
    local SID_L SID_NAME_SAFE HAS_ROW
    SID_L=$(echo "${SID_HEX}" | tr '[:upper:]' '[:lower:]')
    SID_NAME_SAFE=$(echo "${SID_NAME}" | tr '"' "'")
    [ -z "${SID_NAME_SAFE}" ] && SID_NAME_SAFE="SID 0x${SID_L}"

    HAS_ROW=$(awk -F',' -v s="0x${SID_L}" '$2=="CSV_AUDIO"{sid=$6; gsub(/"/, "", sid); if (tolower(sid)==tolower(s)) {f=1; exit}} END{print f+0}' "${MAIN_LOG}" 2>/dev/null)
    if [ "${HAS_ROW:-0}" -gt 0 ] 2>/dev/null; then
      continue
    fi

    echo "$(date -u +%s),CSV_AUDIO,\"${CH}\",${ENS_EID},\"${ENS_NAME_SAFE}\",0x${SID_L},\"${SID_NAME_SAFE}\",0,0,\"\",0,\"\",0,0,\"DAB+/too weak or no audio\",0x0,0x0,\"\",0,\"\",0,\"\",0,0,\"\",\"\",\"\"" >>"${MAIN_LOG}"
  done <"${TMP_SIDS}"

  rm -f "${TMP_SIDS}" 2>/dev/null || true
  echo "$(date -u "+%Y-%m-%dT%T.%N Z"): DAB ${CH}: synthesized weak-audio rows from program list (${SID_CNT} services, no decoder CSV_AUDIO rows)" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
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

function getDabEnsembleKeyFromStderr() {
  local ERRFILE="$1"
  local EID=""
  local ENSNAME=""

  if [ ! -f "${ERRFILE}" ]; then
    return 0
  fi

  ENSNAME=$( grep "ensemblenameHandler:" "${ERRFILE}" 2>/dev/null | head -n1 | sed -n "s/.*ensemblenameHandler: '\([^']*\)'.*/\1/p" )
  EID=$( grep "ensemblenameHandler:" "${ERRFILE}" 2>/dev/null | head -n1 | sed -n "s/.*(EId \([^)]*\)).*/\1/p" )

  if [ -z "${EID}" ]; then
    EID=$( sed -n "s/.*ensembleIdHandler: ensemble (EId \([^)]*\)).*/\1/p" "${ERRFILE}" | head -n1 )
  fi
  if [ -z "${ENSNAME}" ]; then
    ENSNAME="unknown ensemble"
  fi

  if [ ! -z "${EID}" ]; then
    echo -n "0x$(echo "${EID}" | sed 's/^0[xX]//' | tr '[:upper:]' '[:lower:]'),\"${ENSNAME}\""
  fi
}

function getKnownEnsembleNameByEid() {
  local EID_RAW="$1"
  local EID_NORM="$(echo "${EID_RAW}" | tr '[:upper:]' '[:lower:]')"
  local NAME=""

  if [ -f "${rec_path}/dab_ensemble.csv" ]; then
    NAME=$( awk -F',' -v e="${EID_NORM}" '
      {
        eid = tolower($8)
        name = $9
        gsub(/^"/, "", name)
        gsub(/"$/, "", name)
        if (eid == e && tolower(name) != "unknown ensemble" && name != "") {
          print name
          exit
        }
      }
    ' "${rec_path}/dab_ensemble.csv" )
  fi

  if [ -z "${NAME}" ] && [ -f "${REF_DAB_ENS_FILE}" ]; then
    NAME=$( awk -F',' -v e="${EID_NORM}" '
      {
        eid = tolower($1)
        name = $2
        gsub(/^"/, "", name)
        gsub(/"$/, "", name)
        if (eid == e && tolower(name) != "unknown ensemble" && name != "") {
          print name
          exit
        }
      }
    ' "${REF_DAB_ENS_FILE}" )
  fi

  echo -n "${NAME}"
}

function isUnknownEnsembleKey() {
  local KEY="$1"
  local EID=""
  local ENS_RAW=""
  local ENS_NORM=""
  local EID_NORM=""

  EID=$( echo "${KEY}" | awk -F',' '{print $1}' )
  ENS_RAW=$( echo "${KEY}" | awk -F',' '{print $2}' )
  ENS_NORM=$( echo "${ENS_RAW}" | sed 's/^"//; s/"$//; s/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]' )
  EID_NORM=$( echo "${EID}" | tr '[:upper:]' '[:lower:]' )

  if [ "${ENS_NORM}" = "unknown ensemble" ]; then
    return 0
  fi
  if [ "${EID_NORM}" = "0xffffffff" ]; then
    return 0
  fi
  return 1
}

function refEnsembleKeyExists() {
  local KEY="$1"
  local REF_FILE="$2"

  awk -F',' -v key="${KEY}" '
    function trimq(v) {
      gsub(/^"/, "", v)
      gsub(/"$/, "", v)
      return v
    }
    function normname(v) {
      v = trimq(v)
      gsub(/[[:space:]]+$/, "", v)
      return tolower(v)
    }
    BEGIN {
      split(key, ka, ",")
      key_eid = tolower(ka[1])
      key_name = normname(ka[2])
    }
    {
      cand_eid = ""
      cand_name = ""
      if (NF >= 3 && ($1 ~ /^"[0-9]{1,2}[A-Z]"$/ || $1 ~ /^"L[A-Z]"$/)) {
        cand_eid = tolower($2)
        cand_name = normname($3)
      } else if (NF >= 2) {
        cand_eid = tolower($1)
        cand_name = normname($2)
      }
      if (cand_eid == key_eid) {
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

function cleanupDiscoverySnapshotArtifacts() {
  rm -f "${rec_path}"/DAB_*_discovery_keep.log 2>/dev/null || true
  rm -f "${rec_path}"/DAB_*_discovery_keep_stderr.log 2>/dev/null || true
  rm -f "${rec_path}"/.DAB_*_discovery_keep_*.log 2>/dev/null || true
  rm -rf "${rec_path}"/DAB_*_missing_sid_* 2>/dev/null || true
  rm -f "${rec_path}"/.DAB_*_missing_sid_* 2>/dev/null || true
}

# Remove stale artifacts from interrupted runs and ensure cleanup on exit/signals.
cleanupDiscoverySnapshotArtifacts
trap cleanupDiscoverySnapshotArtifacts EXIT INT TERM

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
if [ -z "${FMLIST_SCAN_DAB_RAW_TIMEOUT_SEC}" ]; then
  FMLIST_SCAN_DAB_RAW_TIMEOUT_SEC="180"
fi
if [ -z "${FMLIST_SCAN_DAB_RAW_INIT_MS}" ]; then
  # This is overridden per-clip to RAW_DURATION_SEC*1000 at analysis time; keep as a safe fallback.
  FMLIST_SCAN_DAB_RAW_INIT_MS="${FMLIST_SCAN_DAB_RAW_DURATION_SEC}000"
fi
if [ -z "${FMLIST_SCAN_DAB_RAW_POST_ENSEMBLE_MS}" ]; then
  FMLIST_SCAN_DAB_RAW_POST_ENSEMBLE_MS="2500"
fi
if [ -z "${FMLIST_SCAN_DAB_SID_RETRY_W_MS}" ]; then
  # Max analysis window (ms) for per-SID retry passes in rerunMissingServiceDetailsWithD.
  # Must be >= FMLIST_SCAN_DAB_RAW_INITIAL_SEC * 1000 so the retry analyses at least as
  # much data as the initial full pass.  Using less would guarantee the same failure.
  FMLIST_SCAN_DAB_SID_RETRY_W_MS="5000"
fi
if [ -z "${FMLIST_SCAN_DAB_RAW_INITIAL_SEC}" ]; then
  # For fixed position, the first raw capture uses this shorter duration.
  # If the ensemble row is decoded within this clip all services are recovered
  # via per-SID retries without a second capture.  Only when the ensemble label
  # did not arrive in time (services in FIC but no CSV_ENSEMBLE) will the scanner
  # recapture using the full FMLIST_SCAN_DAB_RAW_DURATION_SEC.
  FMLIST_SCAN_DAB_RAW_INITIAL_SEC="5"
fi
if [ -z "${FMLIST_SCAN_DAB_RAW_REWIND_PER_SERVICE}" ]; then
  FMLIST_SCAN_DAB_RAW_REWIND_PER_SERVICE="0"
fi
if [ -z "${FMLIST_SCAN_DAB_USE_EXTII}" ]; then
  FMLIST_SCAN_DAB_USE_EXTII="1"
fi
if [ -z "${FMLIST_SCAN_DAB_DETAILED_ALL}" ]; then
  # Fixed position is already enabled below by IS_FIXED_POSITION. Keep the
  # mobile default fast: capture/analyze only newly discovered ensembles.
  FMLIST_SCAN_DAB_DETAILED_ALL="0"
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

# Prefer extended TII detection to avoid single-candidate ambiguity.
if [ "${FMLIST_SCAN_DAB_USE_EXTII}" = "1" ] && [[ " ${DABOPT} " != *" -x "* ]]; then
  DABOPT="${DABOPT} -x"
fi

if [ "${FMLIST_SCAN_DAB_SAVE_FIC}" = "1" ]; then
  DABOPT="${DABOPT} -f"
fi

DABOPT_RAW="$( filterDabOptForRaw "${DABOPT}" )"
# Keep one fixed clip per channel/service and rewind for each detailed analysis pass.
# Use -E 0 for file analysis: no need to wait for ensemble sync blocks in a pre-recorded file.
# Keep a short post-ensemble dwell so TII can accumulate before scan-only exits.
DABOPT_RAW="${DABOPT_RAW} -E 0 -W ${FMLIST_SCAN_DAB_RAW_INIT_MS} -A ${FMLIST_SCAN_DAB_RAW_POST_ENSEMBLE_MS} -X"
if [ "${FMLIST_SCAN_DAB_RAW_REWIND_PER_SERVICE}" = "1" ]; then
  DABOPT_RAW="${DABOPT_RAW} -Y"
fi
# Add -D for fixed position; for mobile, will add -D only if ensemble is new
if [ "${FMLIST_UP_POSITION}" = "fixed" ] || [ "${FMLIST_UP_POSITION}" = "fixed position" ]; then
  if [[ " ${DABOPT_RAW} " != *" -D "* ]]; then
    DABOPT_RAW="${DABOPT_RAW} -D"
  fi
fi
DABOPT_DISCOVERY="$( filterDabOptForDiscovery "${DABOPT}" )"

echo "${DTF}: DAB effective opts: base='${DABOPT}' discovery='${DABOPT_DISCOVERY}' raw='${DABOPT_RAW}'" >>${FMLIST_SCAN_RAM_DIR}/scanner.log

DAB_RTLSDR_BIN="$(command -v abra-rtlsdr 2>/dev/null)"
DAB_RAW_BIN="$(command -v abra-raw 2>/dev/null)"
if [ -x "${HOME}/.local/bin/abra-rtlsdr" ]; then
  DAB_RTLSDR_BIN="${HOME}/.local/bin/abra-rtlsdr"
elif [ -x "${HOME}/.local/bin/dab-rtlsdr" ]; then
  DAB_RTLSDR_BIN="${HOME}/.local/bin/dab-rtlsdr"
fi
if [ -x "${HOME}/.local/bin/abra-raw" ]; then
  DAB_RAW_BIN="${HOME}/.local/bin/abra-raw"
elif [ -x "${HOME}/.local/bin/dab-raw" ]; then
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
  local DISC_ENS_LONG="${5:-}"
  local DISC_ENS_SHORT="${6:-}"
  local DTF_LOCAL="$(date -u "+%Y-%m-%dT%T.%N Z")"
  local GPSCOLS="$(cat "${rec_path}/DAB_${CH}.gpscols" 2>/dev/null)"
  local ENS_CSV_CNT=0
  local ENS_LINE=""
  local ENS_NAME=""
  local ENS_EID=""

  ENS_CSV_CNT=$(grep -c ",CSV_ENSEMBLE," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
  ENS_LINE=$(grep ",CSV_ENSEMBLE," "${rec_path}/DAB_${CH}.log" 2>/dev/null | head -n1)
  if [ ! -z "${ENS_LINE}" ]; then
    ENS_EID=$(echo "${ENS_LINE}" | awk -F',' '{ print tolower($4) }')
    ENS_NAME=$(echo "${ENS_LINE}" | awk -F',' '{ print $5 }' | sed 's/^"//; s/"$//; s/[[:space:]]*$//')
    if [ "$(echo "${ENS_NAME}" | tr '[:upper:]' '[:lower:]')" = "unknown ensemble" ] && [ ! -z "${ENS_EID}" ]; then
      KNOWN_NAME=""
      if [ "$(echo "${DISC_ENS_LONG}" | tr '[:upper:]' '[:lower:]')" != "unknown ensemble" ]; then
        KNOWN_NAME="${DISC_ENS_LONG}"
      fi
      if [ -z "${KNOWN_NAME}" ]; then
        KNOWN_NAME="$( getKnownEnsembleNameByEid "${ENS_EID}" )"
      fi
      if [ ! -z "${KNOWN_NAME}" ]; then
        ENS_LINE="$(echo "${ENS_LINE}" | awk -F',' -v OFS=',' -v n="${KNOWN_NAME}" '{$5="\"" n "\""; print }')"
        ENS_NAME="${KNOWN_NAME}"
        # Patch the log file so every CSV row (ENSEMBLE + AUDIO) carries the real name,
        # which makes _ENS_NAME_FINAL guard work and keeps the bundled zip clean.
        # ENS_EID is already lower-case from the awk extraction above.
        _KNOWN_SED=$(printf '%s' "${KNOWN_NAME}" | sed 's/[\[\]\/&]/\\&/g')
        sed -i "s/${ENS_EID},\"unknown ensemble\"/${ENS_EID},\"${_KNOWN_SED}\"/g" "${rec_path}/DAB_${CH}.log"
        echo "${DTF_LOCAL}: DAB ${CH}: replaced unknown ensemble by known name '${KNOWN_NAME}' for EId ${ENS_EID}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      fi
    fi
    if [ ! -z "${DISC_ENS_SHORT}" ]; then
      ENS_SHORT_CURR=$(echo "${ENS_LINE}" | awk -F',' '{ v=$NF; gsub(/^"|"$/, "", v); print tolower(v) }')
      if [ -z "${ENS_SHORT_CURR}" ] || [ "${ENS_SHORT_CURR}" = "unknown" ]; then
        ENS_LINE="$(echo "${ENS_LINE}" | awk -F',' -v OFS=',' -v s="${DISC_ENS_SHORT}" '{$NF="\"" s "\""; print }')"
        echo "${DTF_LOCAL}: DAB ${CH}: replaced unknown shortLabel by discovery short '${DISC_ENS_SHORT}'" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      fi
    fi
    # Only write if EID and name are both valid (not unknown/ffffffff)
    ENS_EID_NORM=$(echo "${ENS_EID}" | tr '[:upper:]' '[:lower:]')
    ENS_NAME_NORM=$(echo "${ENS_NAME}" | tr '[:upper:]' '[:lower:]')
    if [ "${ENS_EID_NORM}" != "0xffffffff" ] && [ "${ENS_NAME_NORM}" != "unknown ensemble" ]; then
      echo "${ENS_LINE}" | sed "s#,CSV_ENSEMBLE,#,${GPSCOLS},#g" >>"${rec_path}/dab_ensemble.csv"
    else
      echo "${DTF_LOCAL}: DAB ${CH}: skipping CSV_ENSEMBLE: EId=${ENS_EID} name='${ENS_NAME}' not useful" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    fi
  fi

  # If decoder aborted before writing CSV_ENSEMBLE, salvage ensemble from stderr.
  if [ "${ENS_CSV_CNT}" -eq 0 ]; then
    ENS_LINE=$(grep "ensemblenameHandler: .*ensemble (EId " "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null | head -n1)
    if [ ! -z "${ENS_LINE}" ]; then
      ENS_NAME=$(echo "${ENS_LINE}" | sed -n "s/.*ensemblenameHandler: '\([^']*\)'.*/\1/p")
      ENS_EID=$(echo "${ENS_LINE}" | sed -n "s/.*(EId \([^)]*\)).*/\1/p")
    else
      ENS_EID=$(sed -n "s/.*ensembleIdHandler: ensemble (EId \([^)]*\)).*/\1/p" "${rec_path}/DAB_${CH}_stderr.log" | head -n1)
    fi

    if [ ! -z "${ENS_EID}" ]; then
      ENS_EID=$(echo "${ENS_EID}" | sed 's/^0[xX]//' | tr '[:upper:]' '[:lower:]')
      if [ -z "${ENS_NAME}" ]; then
        ENS_NAME="unknown ensemble"
      fi
      if [ "$(echo "${ENS_NAME}" | tr '[:upper:]' '[:lower:]')" = "unknown ensemble" ]; then
        KNOWN_NAME="${DISC_ENS_LONG}"
        if [ -z "${KNOWN_NAME}" ]; then
          KNOWN_NAME="$( getKnownEnsembleNameByEid "0x${ENS_EID}" )"
        fi
        if [ ! -z "${KNOWN_NAME}" ]; then
          ENS_NAME="${KNOWN_NAME}"
          echo "${DTF_LOCAL}: DAB ${CH}: synthesized row used known name '${ENS_NAME}' for EId 0x${ENS_EID}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
        fi
      fi
      if [ "$(echo "${ENS_NAME}" | tr '[:upper:]' '[:lower:]')" != "unknown ensemble" ]; then
        echo "$(date -u +%s),${GPSCOLS},\"${CH}\",0x${ENS_EID},\"${ENS_NAME}\"" >>"${rec_path}/dab_ensemble.csv"
        echo "${DTF_LOCAL}: DAB ${CH}: synthesized CSV_ENSEMBLE row from stderr evidence (EId ${ENS_EID})" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      else
        echo "${DTF_LOCAL}: DAB ${CH}: skipping CSV_ENSEMBLE synthesis: EId ${ENS_EID} but ensemble name unknown" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      fi
    fi
  fi

  # Only write audio/packet rows when the ensemble identity is confirmed.
  # If the ensemble name or EId is still unresolved, the rows are useless for upload.
  local _ENS_NAME_FINAL _ENS_EID_FINAL
  _ENS_NAME_FINAL=$(awk -F',' '$2=="CSV_ENSEMBLE" { n=$5; gsub(/^"|"$/, "", n); print tolower(n); exit }' \
    "${rec_path}/DAB_${CH}.log" 2>/dev/null)
  _ENS_EID_FINAL=$(awk -F',' '$2=="CSV_ENSEMBLE" { print tolower($4); exit }' \
    "${rec_path}/DAB_${CH}.log" 2>/dev/null)
  if [ "${_ENS_NAME_FINAL}" = "unknown ensemble" ] || [ -z "${_ENS_NAME_FINAL}" ] || \
     [ "${_ENS_EID_FINAL}" = "0xffffffff" ] || [ -z "${_ENS_EID_FINAL}" ]; then
    echo "${DTF_LOCAL}: DAB ${CH}: skipping audio/packet rows: ensemble identity unresolved (EId='${_ENS_EID_FINAL}' name='${_ENS_NAME_FINAL}')" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  else
    grep ",CSV_GPSCOOR,"  "${rec_path}/DAB_${CH}.log" | sed "s#,CSV_GPSCOOR,#,${GPSCOLS},#g"  >>"${rec_path}/dab_gps.csv"
    grep ",CSV_AUDIO,"    "${rec_path}/DAB_${CH}.log" | sed "s#,CSV_AUDIO,#,${GPSCOLS},#g"    >>"${rec_path}/dab_audio.csv"
    grep ",CSV_PACKET,"   "${rec_path}/DAB_${CH}.log" | sed "s#,CSV_PACKET,#,${GPSCOLS},#g"   >>"${rec_path}/dab_packet.csv"
  fi

  NP=$( cat "${rec_path}/DAB_${CH}_stderr.log" | grep " is part of the ensemble" | grep -c "^programnameHandler:" )
  NE=$( cat "${rec_path}/DAB_${CH}_stderr.log" | grep " is recognized" | grep -c "ensemblenameHandler:" )
  echo "DAB_ENSEMBLE=\"${NE}\"" >>"${rec_path}/DAB_channels.txt"
  echo "NUM_PROGRAMS=\"${NP}\"" >>"${rec_path}/DAB_channels.txt"

  if { [ $NP -eq 0 ] && [ "${ENS_CSV_CNT}" -eq 0 ] && [ $NE -eq 0 ]; } || \
     { [ "${_ENS_EID_FINAL}" = "0xffffffff" ] || [ -z "${_ENS_EID_FINAL}" ]; } && \
     { [ "$(echo "${_ENS_NAME_FINAL}" | tr '[:upper:]' '[:lower:]')" = "unknown ensemble" ] || \
       [ -z "${_ENS_NAME_FINAL}" ]; }; then
    # Determine which branch triggered to write an informative log entry.
    if { [ "${_ENS_EID_FINAL}" = "0xffffffff" ] || [ -z "${_ENS_EID_FINAL}" ]; } && \
       { [ "$(echo "${_ENS_NAME_FINAL}" | tr '[:upper:]' '[:lower:]')" = "unknown ensemble" ] || \
         [ -z "${_ENS_NAME_FINAL}" ]; }; then
      echo "${DTF_LOCAL}: DAB ${CH}: discarding data: EId=${_ENS_EID_FINAL} name='${_ENS_NAME_FINAL}' — unresolvable ensemble identity" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    fi
    if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
      echo "${DTF_LOCAL}: DAB ${CH}: NO station" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      mv "${rec_path}/DAB_${CH}.log" "${rec_path}/DAB_${CH}_no-station.log"
      mv "${rec_path}/DAB_${CH}_stderr.log" "${rec_path}/DAB_${CH}_no-station_stderr.log"
    else
      rm "${rec_path}/DAB_${CH}.log" "${rec_path}/DAB_${CH}_stderr.log"
    fi
  else
    ENSNAME=$( grep "ensemblenameHandler:" "${rec_path}/DAB_${CH}_stderr.log" | head -n1 | sed "s/.*ensemblenameHandler: \('[^']*'\).*\((EId [^)]*)\).*/\1 \2/" )
    LAST_EID="$(sed -n "s/.*ensembleIdHandler: ensemble (EId \([^)]*\)).*/\1/p" "${rec_path}/DAB_${CH}_stderr.log" | head -n1)"
    if [ -z "${LAST_EID}" ]; then
      LAST_EID="$(grep "ensemblenameHandler:" "${rec_path}/DAB_${CH}_stderr.log" | head -n1 | sed -n "s/.*(EId \([^)]*\)).*/\1/p")"
    fi
    if [ -z "${LAST_EID}" ]; then
      LAST_EID="$(grep ",CSV_ENSEMBLE," "${rec_path}/DAB_${CH}.log" 2>/dev/null | head -n1 | awk -F',' '{print $4}')"
    fi
    LAST_EID="$(echo "${LAST_EID}" | sed 's/^0[xX]//; s/"//g' | tr '[:lower:]' '[:upper:]')"
    if [ -z "${ENSNAME}" ]; then
      ENSNAME="'unknown ensemble'"
    fi
    if [ "${ENSNAME}" = "'unknown ensemble'" ]; then
      # Prefer the resolved name from processChannelData (ENS_NAME) over DISC_ENS_LONG
      # because DISC_ENS_LONG may itself be 'unknown ensemble' for fixed-position scans
      # where discovery was skipped.
      if [ -n "${ENS_NAME}" ] && [ "$(echo "${ENS_NAME}" | tr '[:upper:]' '[:lower:]')" != "unknown ensemble" ]; then
        ENSNAME="'${ENS_NAME}'"
        [ ! -z "${LAST_EID}" ] && ENSNAME="${ENSNAME} (EId ${LAST_EID})"
      elif [ ! -z "${DISC_ENS_LONG}" ] && [ "$(echo "${DISC_ENS_LONG}" | tr '[:upper:]' '[:lower:]')" != "unknown ensemble" ]; then
        ENSNAME="'${DISC_ENS_LONG}'"
        [ ! -z "${LAST_EID}" ] && ENSNAME="${ENSNAME} (EId ${LAST_EID})"
      elif [ ! -z "${LAST_EID}" ]; then
        ENSNAME="'unknown ensemble' (EId ${LAST_EID})"
      fi
    fi

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
        CH_RAW_FINAL="${CH_RAW%_temp.raw}.raw"
        mv -f "${CH_RAW}" "${CH_RAW_FINAL}"
        echo "${DTF_LOCAL}: DAB ${CH}: keeping raw clip (first-time ensemble) ${CH_RAW_FINAL}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
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
  if [ -n "${GPSLAT}" ] && [ "${GPSMODE:-0}" -ge 2 ] 2>/dev/null; then
    echo "${GPSCOLS}" >"${FMLIST_SCAN_RAM_DIR}/last_good_gpscols.txt"
  elif [ -z "${GPSLAT}" ] && [ -f "${FMLIST_SCAN_RAM_DIR}/last_good_gpscols.txt" ]; then
    GPSCOLS="$(cat "${FMLIST_SCAN_RAM_DIR}/last_good_gpscols.txt")"
  fi
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
    echo -e "$(date -u "+%Y-%m-%dT%T Z"): Temperature at scanDAB.sh before dab-rtlsdr -C ${CH}: $(cat /sys/class/thermal/thermal_zone*/temp | awk '{printf "%.1f°C ", $1/1000}')" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    echo "$(date -u +%s), $(cat /sys/class/thermal/thermal_zone*/temp | tr '\n' ' ')" >>${FMLIST_SCAN_RAM_DIR}/cputemp.csv
  fi

  DTFFIC="$(date -u "+%Y-%m-%dT%H%M%S")"
  if [ "${FMLIST_SCAN_DAB_ANALYZE_FROM_RAW}" = "1" ]; then
    IS_NEW_ENS="0"
    IS_UNKNOWN_ENS="0"
    DISC_UNKNOWN_ENS="0"
    DISC_ENS_LONG=""
    DISC_ENS_SHORT=""
    DISCOVERY_LOG_SNAPSHOT="$(mktemp "${rec_path}/.DAB_${CH}_discovery_keep_XXXXXX.log")"
    DISCOVERY_ERR_SNAPSHOT="$(mktemp "${rec_path}/.DAB_${CH}_discovery_keep_stderr_XXXXXX.log")"
    SHOULD_REGISTER_NEW="0"
    KEEP_RAW_FILE="0"
    DISC_NUM_PROGRAMS="0"
    DISC_NUM_SIDS="0"
    CH_RAW=""
    DABOPT_FALLBACK="${DABOPT_DISCOVERY}"
    
    # For fixed-position known ensembles, disable SNR abort in live fallback to allow detailed analysis
    if [ "${IS_FIXED_POSITION}" = "1" ]; then
      DABOPT_FALLBACK="$(echo " ${DABOPT_FALLBACK} " | sed -E 's/[[:space:]]-E[[:space:]]+[0-9-]+/ /g; s/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/ /g')"
    fi

    # Discovery pass: only needed for mobile/non-fixed-position to get the ensemble key
    # before deciding whether to capture a raw clip.  For fixed position we always capture
    # a raw clip and derive all metadata from the dab-raw analysis — skipping discovery
    # saves ~5 s per channel (the full -W 5000 discovery window).
    if [ "${IS_FIXED_POSITION}" != "1" ]; then
    "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_DISCOVERY} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
    rm -f "${rec_path}/DAB_${CH}_initial_ensemble.csv" 2>/dev/null
    rm -f "${rec_path}/DAB_${CH}_initial_stderr.log" 2>/dev/null
    rm -f "${rec_path}/DAB_${CH}_discovery_ensemble.csv" 2>/dev/null
    rm -f "${rec_path}/DAB_${CH}_discovery_ensemble.csvrow" 2>/dev/null
    rm -f "${rec_path}/DAB_${CH}_discovery.log" 2>/dev/null
    rm -f "${rec_path}/DAB_${CH}_discovery_stderr.log" 2>/dev/null

    DAB_ENS_KEY="$( getDabEnsembleKeyFromLog "${CH}" "${rec_path}/DAB_${CH}.log" )"
    DISC_NUM_PROGRAMS=$(grep -c "^programnameHandler:.* is part of the ensemble" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null || true)
    DISC_NUM_SIDS=$(grep "^programnameHandler:.* is part of the ensemble" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null | sed -n "s/.*(SId \([0-9A-Fa-f]\+\)).*/\1/p" | tr '[:lower:]' '[:upper:]' | sort -u | wc -l)
    if [ -z "${DISC_NUM_PROGRAMS}" ]; then
      DISC_NUM_PROGRAMS="0"
    fi
    if [ -z "${DISC_NUM_SIDS}" ]; then
      DISC_NUM_SIDS="0"
    fi
    if [ -z "${DAB_ENS_KEY}" ]; then
      DAB_ENS_KEY="$( getDabEnsembleKeyFromStderr "${rec_path}/DAB_${CH}_stderr.log" )"
      if [ ! -z "${DAB_ENS_KEY}" ]; then
        echo "${DTF}: DAB ${CH}: derived ensemble key from stderr (${DAB_ENS_KEY})" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      fi
    fi
    DISC_ENS_LONG=$( grep "ensemblenameHandler:" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null | head -n1 | sed -n "s/.*ensemblenameHandler: '\([^']*\)'.*/\1/p" | sed 's/[[:space:]]*$//' )
    DISC_ENS_SHORT=$( grep "ensemblenameHandler:" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null | head -n1 | sed -n "s/.*\/ '\([^']*\)'.*/\1/p" | sed 's/[[:space:]]*$//' )
    if [ -z "${DISC_ENS_LONG}" ] && [ ! -z "${DAB_ENS_KEY}" ]; then
      DISC_ENS_LONG=$(echo "${DAB_ENS_KEY}" | awk -F',' '{print $2}' | sed 's/^"//; s/"$//; s/[[:space:]]*$//')
    fi

    if [ ! -z "${DAB_ENS_KEY}" ] && isUnknownEnsembleKey "${DAB_ENS_KEY}"; then
      DISC_UNKNOWN_ENS="1"
    fi

    if [ "${DISC_UNKNOWN_ENS}" = "1" ] && [ ${DISC_NUM_PROGRAMS} -le 2 ]; then
      DABOPT_DISCOVERY_RETRY="$( tuneDabOptForUnknownEnsembleRetry "${DABOPT_DISCOVERY}" )"
      echo "${DTF}: DAB ${CH}: unknown/weak discovery (${DISC_NUM_PROGRAMS} program lines); retrying with longer timeout opts: ${DABOPT_DISCOVERY_RETRY}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_DISCOVERY_RETRY} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"

      DAB_ENS_KEY="$( getDabEnsembleKeyFromLog "${CH}" "${rec_path}/DAB_${CH}.log" )"
      DISC_NUM_PROGRAMS=$(grep -c "^programnameHandler:.* is part of the ensemble" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null || true)
      DISC_NUM_SIDS=$(grep "^programnameHandler:.* is part of the ensemble" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null | sed -n "s/.*(SId \([0-9A-Fa-f]\+\)).*/\1/p" | tr '[:lower:]' '[:upper:]' | sort -u | wc -l)
      if [ -z "${DISC_NUM_PROGRAMS}" ]; then
        DISC_NUM_PROGRAMS="0"
      fi
      if [ -z "${DISC_NUM_SIDS}" ]; then
        DISC_NUM_SIDS="0"
      fi
      if [ -z "${DAB_ENS_KEY}" ]; then
        DAB_ENS_KEY="$( getDabEnsembleKeyFromStderr "${rec_path}/DAB_${CH}_stderr.log" )"
      fi
      DISC_ENS_LONG=$( grep "ensemblenameHandler:" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null | head -n1 | sed -n "s/.*ensemblenameHandler: '\([^']*\)'.*/\1/p" | sed 's/[[:space:]]*$//' )
      DISC_ENS_SHORT=$( grep "ensemblenameHandler:" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null | head -n1 | sed -n "s/.*\/ '\([^']*\)'.*/\1/p" | sed 's/[[:space:]]*$//' )
      if [ -z "${DISC_ENS_LONG}" ] && [ ! -z "${DAB_ENS_KEY}" ]; then
        DISC_ENS_LONG=$(echo "${DAB_ENS_KEY}" | awk -F',' '{print $2}' | sed 's/^"//; s/"$//; s/[[:space:]]*$//')
      fi
      echo "${DTF}: DAB ${CH}: retry discovery result key='${DAB_ENS_KEY}' program lines=${DISC_NUM_PROGRAMS} unique SIDs=${DISC_NUM_SIDS}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    elif [ "${DISC_UNKNOWN_ENS}" = "1" ] && [ ${DISC_NUM_PROGRAMS} -gt 2 ]; then
      # Channel has programs already but ensemble label was not received in time.
      # Run a targeted name-only retry without overwriting the main log files so
      # the already-discovered service list is preserved.
      local _DISC_NAME_RETRY_STDERR="${rec_path}/.DAB_${CH}_name_retry_stderr.tmp"
      DABOPT_DISCOVERY_RETRY="$( tuneDabOptForUnknownEnsembleRetry "${DABOPT_DISCOVERY}" )"
      echo "${DTF}: DAB ${CH}: unknown ensemble name with ${DISC_NUM_PROGRAMS} programs; name-only retry: ${DABOPT_DISCOVERY_RETRY}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_DISCOVERY_RETRY} 1>/dev/null 2>"${_DISC_NAME_RETRY_STDERR}"
      _RETRY_ENS_LONG=$( grep "ensemblenameHandler:" "${_DISC_NAME_RETRY_STDERR}" 2>/dev/null | head -n1 | sed -n "s/.*ensemblenameHandler: '\([^']*\)'.*/\1/p" | sed 's/[[:space:]]*$//' )
      _RETRY_ENS_SHORT=$( grep "ensemblenameHandler:" "${_DISC_NAME_RETRY_STDERR}" 2>/dev/null | head -n1 | sed -n "s/.*\/ '\([^']*\)'.*/\1/p" | sed 's/[[:space:]]*$//' )
      if [ -n "${_RETRY_ENS_LONG}" ] && [ "$(echo "${_RETRY_ENS_LONG}" | tr '[:upper:]' '[:lower:]')" != "unknown ensemble" ]; then
        _RETRY_EID=$( grep "ensemblenameHandler:" "${_DISC_NAME_RETRY_STDERR}" 2>/dev/null | head -n1 | sed -n "s/.*(EId \([^)]*\)).*/\1/p" )
        [ -z "${_RETRY_EID}" ] && _RETRY_EID=$(sed -n "s/.*ensembleIdHandler: ensemble (EId \([^)]*\)).*/\1/p" "${_DISC_NAME_RETRY_STDERR}" | head -n1)
        if [ -n "${_RETRY_EID}" ]; then
          _RETRY_EID_NORM=$(echo "${_RETRY_EID}" | sed 's/^0[xX]//' | tr '[:upper:]' '[:lower:]')
          DAB_ENS_KEY="0x${_RETRY_EID_NORM},\"${_RETRY_ENS_LONG}\""
        fi
        DISC_ENS_LONG="${_RETRY_ENS_LONG}"
        DISC_ENS_SHORT="${_RETRY_ENS_SHORT}"
        DISC_UNKNOWN_ENS="0"
        echo "${DTF}: DAB ${CH}: name-only retry resolved ensemble to '${_RETRY_ENS_LONG}' (key=${DAB_ENS_KEY})" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      else
        echo "${DTF}: DAB ${CH}: name-only retry did not resolve ensemble name; keeping FIC data without name" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      fi
      rm -f "${_DISC_NAME_RETRY_STDERR}" 2>/dev/null || true
    fi
    fi # end IS_FIXED_POSITION != 1 (discovery pass)

    # Keep a final discovery snapshot before any detailed/raw analysis may overwrite logs.
    cp -f "${rec_path}/DAB_${CH}.log" "${DISCOVERY_LOG_SNAPSHOT}" 2>/dev/null || true
    cp -f "${rec_path}/DAB_${CH}_stderr.log" "${DISCOVERY_ERR_SNAPSHOT}" 2>/dev/null || true

    REF_DAB_ENS_FILE="${HOME}/.config/fmlist_scan/${FMLIST_QTH_PREFIX}_dab_ensembles.csv"

    if [ ! -z "${DAB_ENS_KEY}" ]; then
      if isUnknownEnsembleKey "${DAB_ENS_KEY}"; then
        IS_UNKNOWN_ENS="1"
        echo "${DTF}: DAB ${CH}: unknown ensemble key detected (${DAB_ENS_KEY}); will not register as NEW" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      fi
    fi

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

      if [ "${IS_UNKNOWN_ENS}" = "1" ]; then
        IS_NEW_ENS="0"
      elif refEnsembleKeyExists "${DAB_ENS_KEY}" "${REF_DAB_ENS_FILE}"; then
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

    SHOULD_RUN_DETAILED="0"
    if [ "${FMLIST_SCAN_DAB_DETAILED_ALL}" = "1" ]; then
      SHOULD_RUN_DETAILED="1"
    elif [ "${IS_FIXED_POSITION}" = "1" ] || [ "${IS_NEW_ENS}" = "1" ]; then
      SHOULD_RUN_DETAILED="1"
    fi

    # For fixed position, always proceed to raw capture even without a discovery key;
    # the ensemble key will be derived from the dab-raw analysis output below.
    if [ "${SHOULD_RUN_DETAILED}" = "1" ] && { [ "${IS_FIXED_POSITION}" = "1" ] || [ ! -z "${DAB_ENS_KEY}" ]; }; then
      # For mobile mode, add -D to the fallback so live analysis can decode audio details.
      # For fixed position, -D must NOT be added: the live fallback is only used as a
      # last-resort ensemble-identity recovery after raw-file analysis failures.
      # With -D on a 10-20 service ensemble the live fallback takes O(N) minutes —
      # audio details can only ever come from raw capture for fixed-position scans anyway.
      if [ "${IS_FIXED_POSITION}" != "1" ] && [[ " ${DABOPT_FALLBACK} " != *" -D "* ]]; then
        DABOPT_FALLBACK="${DABOPT_FALLBACK} -D"
      fi
      RAW_DURATION_SEC="${FMLIST_SCAN_DAB_RAW_DURATION_SEC}"
      # Fixed position: use a shorter initial clip to save time; weak-signal channels
      # are handled by the too-weak-signal early exit in rerunMissingServiceDetailsWithD.
      if [ "${IS_FIXED_POSITION}" = "1" ] && \
         [ "${FMLIST_SCAN_DAB_RAW_INITIAL_SEC:-0}" -gt 0 ] 2>/dev/null && \
         [ "${FMLIST_SCAN_DAB_RAW_INITIAL_SEC}" -lt "${FMLIST_SCAN_DAB_RAW_DURATION_SEC}" ] 2>/dev/null; then
        RAW_DURATION_SEC="${FMLIST_SCAN_DAB_RAW_INITIAL_SEC}"
      fi
      CH_FREQ="$( chanFreq "${CH}" )"
      DTFRAW="$(date -u "+%Y%m%dT%H%M%SZ")"
      DAB_EID="$( getDabEnsembleIdFromStderr "${rec_path}/DAB_${CH}_stderr.log" )"
      if [ "${DAB_EID}" = "unknown" ]; then
        CH_RAW="${rec_path}/DAB_${CH}_${DTFRAW}_${RAW_DURATION_SEC}sec_temp.raw"
      else
        CH_RAW="${rec_path}/DAB_${CH}_${DAB_EID}_${DTFRAW}_${RAW_DURATION_SEC}sec_temp.raw"
      fi
      NSMP="$[ ${RAW_DURATION_SEC} * 2048000 ]"

      if [ -z "${CH_FREQ}" ]; then
        echo "${DTF}: DAB ${CH}: cannot map channel to frequency for raw capture" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      else
        echo "rtl_sdr -f ${CH_FREQ} -s 2048000 -n ${NSMP} ${FMLIST_DAB_RTLSDR_OPT} ${CH_RAW}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
        timeout -s SIGTERM -k 2 $[${RAW_DURATION_SEC} + 3] rtl_sdr -f ${CH_FREQ} -s 2048000 -n ${NSMP} ${FMLIST_DAB_RTLSDR_OPT} "${CH_RAW}" >"${rec_path}/DAB_${CH}_rtl.log" 2>&1
        RTL_RC=$?

        if { [ ${RTL_RC} -ne 0 ] && [ ${RTL_RC} -ne 124 ]; } || [ ! -s "${CH_RAW}" ]; then
          echo "${DTF}: DAB ${CH}: raw capture failed (rc=${RTL_RC}); retrying live fallback with opts: ${DABOPT_FALLBACK}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
          "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_FALLBACK} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
          CH_RAW=""
          KEEP_RAW_FILE="0"
        else
          if [ "${IS_NEW_ENS}" = "1" ]; then
            SHOULD_REGISTER_NEW="1"
          fi
          # Ensure detailed decoder output so CSV_AUDIO rows are always produced.
          DABOPT_RAW_FOR_ANALYSIS="${DABOPT_RAW}"
          if [[ " ${DABOPT_RAW_FOR_ANALYSIS} " != *" -D "* ]]; then
            DABOPT_RAW_FOR_ANALYSIS="${DABOPT_RAW_FOR_ANALYSIS} -D"
          fi
          # Set -W to the full clip duration: dab-raw must process the entire file to allow late-arriving FIG 1/0 (ensemble label) to be decoded.
          _RAW_W_MS=$((RAW_DURATION_SEC * 1000))
          DABOPT_RAW_FOR_ANALYSIS=$(echo " ${DABOPT_RAW_FOR_ANALYSIS} " | sed -E "s/ -W [0-9]+ / -W ${_RAW_W_MS} /g")
          # In file mode, -A (post-ensemble early exit) must not shrink the analysis window.
          # Replace -A <positive> with -A -1 so waitingTime is never overridden by ensemble recognition.
          DABOPT_RAW_FOR_ANALYSIS=$(echo " ${DABOPT_RAW_FOR_ANALYSIS} " | sed -E 's/ -A [0-9]+ / -A -1 /g')
          echo "${DTF}: DAB ${CH}: dab-raw detailed audio analysis enabled" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
          echo "${DAB_RAW_BIN} -F ${CH_RAW} ${DABOPT_RAW_FOR_ANALYSIS}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
          runDabRaw "${rec_path}/DAB_${CH}.log" "${rec_path}/DAB_${CH}_stderr.log" -F "${CH_RAW}" ${DABOPT_RAW_FOR_ANALYSIS}
          DABRAW_RC=$?
          # Fix channel label in CSV output: dab-raw without -C writes internal sub-channel ID instead of band channel (e.g. "11C" instead of "6A")
          sed -i -E "s/(,CSV_(AUDIO|ENSEMBLE|GPSCOOR|PACKET),\")[^\"]*(\")/\1${CH}\3/g" "${rec_path}/DAB_${CH}.log"
          DABRAW_CSV_ENS=$(grep -c ",CSV_ENSEMBLE," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
          DABRAW_CSV_AUD=$(grep -c ",CSV_AUDIO," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
          DABRAW_CSV_PKT=$(grep -c ",CSV_PACKET," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
          DABRAW_TOO_WEAK_IN_CSV=$(grep -c ",CSV_AUDIO,.*too weak signal" "${rec_path}/DAB_${CH}.log" 2>/dev/null)
          DABRAW_CSV_AUD_NONWEAK=$(grep ",CSV_AUDIO," "${rec_path}/DAB_${CH}.log" 2>/dev/null | grep -vcE '"DAB\+/audio"|"DAB/audio"|too weak signal|too weak or no audio|AAC-LC Mono 32kHz' || true)
          DABRAW_LIST_LINES=$(grep -c "^LIST: SID " "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null || true)
          DABRAW_CSV_SID_UNIQ=$(countCsvUniqueServiceSids "${rec_path}/DAB_${CH}.log")
          DABRAW_SERVICE_EVIDENCE="${DABRAW_LIST_LINES}"
          if [ "${DABRAW_CSV_SID_UNIQ:-0}" -gt "${DABRAW_SERVICE_EVIDENCE:-0}" ] 2>/dev/null; then
            DABRAW_SERVICE_EVIDENCE="${DABRAW_CSV_SID_UNIQ}"
          fi
          DABRAW_CRASHED="0"
          DABRAW_PARTIAL_AUDIO_FAIL="0"
          if [ -z "${DABRAW_TOO_WEAK_IN_CSV}" ]; then DABRAW_TOO_WEAK_IN_CSV=0; fi
          if [ -z "${DABRAW_CSV_AUD_NONWEAK}" ]; then DABRAW_CSV_AUD_NONWEAK=0; fi
          if [ -z "${DABRAW_LIST_LINES}" ]; then DABRAW_LIST_LINES=0; fi
          if [ -z "${DABRAW_CSV_PKT}" ]; then DABRAW_CSV_PKT=0; fi
          if [ -z "${DABRAW_CSV_SID_UNIQ}" ]; then DABRAW_CSV_SID_UNIQ=0; fi
          if [ -z "${DABRAW_SERVICE_EVIDENCE}" ]; then DABRAW_SERVICE_EVIDENCE=0; fi
          if grep -qi "terminate called without an active exception" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null; then
            DABRAW_CRASHED="1"
          fi

          # Fixed position: derive ensemble key and SID count from raw analysis output
          # (discovery was skipped; all metadata comes from dab-raw itself).
          if [ "${IS_FIXED_POSITION}" = "1" ] && [ -z "${DAB_ENS_KEY}" ]; then
            DAB_ENS_KEY="$( getDabEnsembleKeyFromLog "${CH}" "${rec_path}/DAB_${CH}.log" )"
            if [ -z "${DAB_ENS_KEY}" ]; then
              DAB_ENS_KEY="$( getDabEnsembleKeyFromStderr "${rec_path}/DAB_${CH}_stderr.log" )"
              [ -n "${DAB_ENS_KEY}" ] && echo "${DTF}: DAB ${CH}: derived key from analysis stderr (${DAB_ENS_KEY})" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            fi
            if [ -n "${DAB_ENS_KEY}" ]; then
              DISC_ENS_LONG=$( grep "ensemblenameHandler:" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null | head -n1 | sed -n "s/.*ensemblenameHandler: '\([^']*\)'.*/\1/p" | sed 's/[[:space:]]*$//' )
              [ -z "${DISC_ENS_LONG}" ] && DISC_ENS_LONG=$(echo "${DAB_ENS_KEY}" | awk -F',' '{print $2}' | sed 's/^"//; s/"$//; s/[[:space:]]*$//')
              DISC_ENS_SHORT=$( grep "ensemblenameHandler:" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null | head -n1 | sed -n "s/.*\/ '\([^']*\)'.*/\1/p" | sed 's/[[:space:]]*$//' )
              if isUnknownEnsembleKey "${DAB_ENS_KEY}"; then
                IS_UNKNOWN_ENS="1"
                echo "${DTF}: DAB ${CH}: unknown ensemble key (${DAB_ENS_KEY})" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
              elif ! refEnsembleKeyExists "${DAB_ENS_KEY}" "${REF_DAB_ENS_FILE}"; then
                IS_NEW_ENS="1"
                KEEP_RAW_FILE="1"
                SHOULD_REGISTER_NEW="1"
                echo "${DTF}: DAB ${CH}: new multiplex detected post-analysis (${DAB_ENS_KEY})" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
              fi
            fi
            DISC_NUM_SIDS=$(grep "^programnameHandler:.* is part of the ensemble" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null | sed -n "s/.*(SId \([0-9A-Fa-f]\+\)).*/\1/p" | tr '[:lower:]' '[:upper:]' | sort -u | wc -l | tr -d ' ')
            [ -z "${DISC_NUM_SIDS}" ] && DISC_NUM_SIDS="0"
            echo "${DTF}: DAB ${CH}: fixed-pos analysis: key='${DAB_ENS_KEY}' SIDs=${DISC_NUM_SIDS} new=${IS_NEW_ENS}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
          fi

          # Detect too-weak at channel level:
          # - no CSV at all + explicit too-weak hint
          # - ALL audio rows are marked too weak
          DABRAW_TOO_WEAK="0"
          if [ ${DABRAW_CSV_ENS} -eq 0 ] && [ ${DABRAW_CSV_AUD} -eq 0 ]; then
            if grep -qi "too weak" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null || grep -qi "too weak" "${rec_path}/DAB_${CH}.log" 2>/dev/null; then
              DABRAW_TOO_WEAK="1"
            fi
          elif [ ${DABRAW_CSV_ENS} -gt 0 ] && [ ${DABRAW_CSV_AUD} -eq 0 ] && [ ${DABRAW_CSV_PKT} -eq 0 ] && [ ${DISC_NUM_SIDS:-0} -eq 0 ]; then
            # Ensemble recognized but no services were decoded at all.
            # Treat as weak-signal channel so fixed-position retry path can kick in.
            DABRAW_TOO_WEAK="1"
            echo "${DTF}: DAB ${CH}: ensemble decoded but no service/audio rows; treating as too weak signal" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
          elif [ ${DABRAW_CSV_AUD} -gt 0 ] && [ ${DABRAW_CSV_AUD_NONWEAK} -eq 0 ] && [ ${DABRAW_TOO_WEAK_IN_CSV} -gt 0 ]; then
            DABRAW_TOO_WEAK="1"
          fi

          # 15s fixed-position clips can rarely crash. If they do, escalate to longer fallback capture.
          if [ "${IS_FIXED_POSITION}" = "1" ] && [ ${RAW_DURATION_SEC} -le 15 ] && [ ${DISC_NUM_SIDS} -ge 2 ]; then
            if { [ ${DABRAW_RC} -ne 0 ] || [ "${DABRAW_CRASHED}" = "1" ]; } && \
               { [ ${DABRAW_CSV_AUD_NONWEAK} -le 1 ] || [ ${DABRAW_LIST_LINES} -lt ${DISC_NUM_SIDS} ]; }; then
              DABRAW_PARTIAL_AUDIO_FAIL="1"
            fi
          fi

          if [ ${DABRAW_RC} -ne 0 ] && [ ${DABRAW_CSV_ENS} -eq 0 ] && [ ${DABRAW_CSV_AUD} -eq 0 ] && [ "${DABRAW_TOO_WEAK}" = "0" ]; then
            echo "${DTF}: DAB ${CH}: dab-raw failed (rc=${DABRAW_RC}) without CSV output and no 'too weak' hint; keeping discovery-only result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_FALLBACK} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
            # The raw file is unusable (produced no output). Clear it so that the
            # per-SID rerun below does not re-analyse the same bad file and falsely
            # mark every service as "DAB+/too weak or no audio".
            rm -f "${CH_RAW}" 2>/dev/null || true
            CH_RAW=""
            KEEP_RAW_FILE="0"
          elif [ "${DABRAW_PARTIAL_AUDIO_FAIL}" = "1" ]; then
            # First try to recover missing services from the same clip before recapturing longer clips.
            _NOREWIND_W=$((${RAW_DURATION_SEC:-15} * 1000))
            DABOPT_RAW_NOREWIND="$(echo " ${DABOPT_RAW_FOR_ANALYSIS} " | sed -E "s/[[:space:]]-X([[:space:]]|$)/ /g; s/[[:space:]]-Y([[:space:]]|$)/ /g; s/[[:space:]]-E[[:space:]]+[0-9]+/ -E 0/g; s/[[:space:]]-W [0-9]+/ -W ${_NOREWIND_W}/g; s/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/ /g")"
            echo "${DTF}: DAB ${CH}: partial audio listing after crash; retrying existing clip without rewind first" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            echo "${DAB_RAW_BIN} -F ${CH_RAW} ${DABOPT_RAW_NOREWIND}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            runDabRaw "${rec_path}/DAB_${CH}.log" "${rec_path}/DAB_${CH}_stderr.log" -F "${CH_RAW}" ${DABOPT_RAW_NOREWIND}
            DABRAW_RC=$?
            sed -i -E "s/(,CSV_(AUDIO|ENSEMBLE|GPSCOOR|PACKET),\")[^\"]*(\")/\1${CH}\3/g" "${rec_path}/DAB_${CH}.log"
            DABRAW_CSV_ENS=$(grep -c ",CSV_ENSEMBLE," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
            DABRAW_CSV_AUD=$(grep -c ",CSV_AUDIO," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
            DABRAW_CSV_AUD_NONWEAK=$(grep ",CSV_AUDIO," "${rec_path}/DAB_${CH}.log" 2>/dev/null | grep -vcE '"DAB\+/audio"|"DAB/audio"|too weak signal|too weak or no audio|AAC-LC Mono 32kHz' || true)
            DABRAW_LIST_LINES=$(grep -c "^LIST: SID " "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null || true)
            DABRAW_CRASHED="0"
            if [ -z "${DABRAW_CSV_AUD_NONWEAK}" ]; then DABRAW_CSV_AUD_NONWEAK=0; fi
            if [ -z "${DABRAW_LIST_LINES}" ]; then DABRAW_LIST_LINES=0; fi
            if grep -qi "terminate called without an active exception" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null; then
              DABRAW_CRASHED="1"
            fi
            DABRAW_PARTIAL_AUDIO_FAIL="0"
            if [ "${IS_FIXED_POSITION}" = "1" ] && [ ${RAW_DURATION_SEC} -le 15 ] && [ ${DISC_NUM_SIDS} -ge 2 ]; then
              if { [ ${DABRAW_RC} -ne 0 ] || [ "${DABRAW_CRASHED}" = "1" ]; } && \
                 { [ ${DABRAW_CSV_AUD_NONWEAK} -le 1 ] || [ ${DABRAW_LIST_LINES} -lt ${DISC_NUM_SIDS} ]; }; then
                DABRAW_PARTIAL_AUDIO_FAIL="1"
              fi
            fi

            if [ "${DABRAW_PARTIAL_AUDIO_FAIL}" = "1" ] && [ "${IS_FIXED_POSITION}" = "1" ] && [ ! -z "${CH_FREQ}" ]; then
              # Still incomplete: now escalate to long fallback capture.
              RETRY_RAW_DURATION="${FMLIST_SCAN_DAB_RAW_DURATION_SEC}"
              _RETRY_W_MS=$((RETRY_RAW_DURATION * 1000))
              DTFRAW_RETRY="$(date -u "+%Y%m%dT%H%M%SZ")"
              CH_RAW_RETRY="${rec_path}/DAB_${CH}_${DAB_EID}_${DTFRAW_RETRY}_${RETRY_RAW_DURATION}sec_temp.raw"
              NSMP_RETRY=$[ ${RETRY_RAW_DURATION} * 2048000 ]
              DABOPT_RAW_NOREWIND="$(echo " ${DABOPT_RAW_FOR_ANALYSIS} " | sed -E "s/[[:space:]]-X([[:space:]]|$)/ /g; s/[[:space:]]-Y([[:space:]]|$)/ /g; s/[[:space:]]-E[[:space:]]+[0-9]+/ -E 0/g; s/[[:space:]]-W [0-9]+/ -W ${_RETRY_W_MS}/g; s/[[:space:]]-A [0-9-]+/ -A -1/g; s/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/ /g")"
              echo "${DTF}: DAB ${CH}: still incomplete after no-rewind retry; recapturing ${RETRY_RAW_DURATION}s" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
              echo "rtl_sdr -f ${CH_FREQ} -s 2048000 -n ${NSMP_RETRY} ${FMLIST_DAB_RTLSDR_OPT} ${CH_RAW_RETRY}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
              timeout -s SIGTERM -k 2 $[${RETRY_RAW_DURATION} + 3] rtl_sdr -f ${CH_FREQ} -s 2048000 -n ${NSMP_RETRY} ${FMLIST_DAB_RTLSDR_OPT} "${CH_RAW_RETRY}" >"${rec_path}/DAB_${CH}_rtl_retry.log" 2>&1
              RTL_RETRY_RC=$?
              if { [ ${RTL_RETRY_RC} -eq 0 ] || [ ${RTL_RETRY_RC} -eq 124 ]; } && [ -s "${CH_RAW_RETRY}" ]; then
                rm -f "${CH_RAW}" 2>/dev/null
                CH_RAW="${CH_RAW_RETRY}"
                echo "${DAB_RAW_BIN} -F ${CH_RAW} ${DABOPT_RAW_NOREWIND}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
                runDabRaw "${rec_path}/DAB_${CH}.log" "${rec_path}/DAB_${CH}_stderr.log" -F "${CH_RAW}" ${DABOPT_RAW_NOREWIND}
                sed -i -E "s/(,CSV_(AUDIO|ENSEMBLE|GPSCOOR|PACKET),\")[^\"]*(\")/\1${CH}\3/g" "${rec_path}/DAB_${CH}.log"
                DABRAW_CSV_ENS=$(grep -c ",CSV_ENSEMBLE," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
                DABRAW_CSV_AUD=$(grep -c ",CSV_AUDIO," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
                if [ ${DABRAW_CSV_ENS} -eq 0 ] && [ ${DABRAW_CSV_AUD} -eq 0 ]; then
                  echo "${DTF}: DAB ${CH}: longer-clip retry produced no CSV; keeping discovery-only result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
                  rm -f "${CH_RAW}" 2>/dev/null || true; CH_RAW=""; KEEP_RAW_FILE="0"
                  "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_FALLBACK} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
                else
                  DABRAW_LIST_LINES=$(grep -c "^LIST: SID " "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null || true)
                  if [ -z "${DABRAW_LIST_LINES}" ]; then DABRAW_LIST_LINES=0; fi
                  DABRAW_CRASHED="0"
                  if grep -qi "terminate called without an active exception" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null; then
                    DABRAW_CRASHED="1"
                  fi
                  if [ "${DABRAW_CRASHED}" = "1" ] && [ ${DISC_NUM_SIDS} -ge 2 ] && [ ${DABRAW_LIST_LINES} -lt ${DISC_NUM_SIDS} ]; then
                    echo "${DTF}: DAB ${CH}: long-retry still incomplete (${DABRAW_LIST_LINES}/${DISC_NUM_SIDS}) after crash; keeping strict -D mode" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
                    rerunMissingServiceDetailsWithD "${CH}" "${CH_RAW}" "${DABOPT_RAW_NOREWIND}" "${DISC_NUM_SIDS}"
                  fi
                  echo "${DTF}: DAB ${CH}: longer-clip retry produced CSV; keeping dab-raw result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
                fi
              else
                echo "${DTF}: DAB ${CH}: longer-clip capture failed (rc=${RTL_RETRY_RC}); keeping discovery-only result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
                rm -f "${CH_RAW_RETRY}" 2>/dev/null
                rm -f "${CH_RAW}" 2>/dev/null || true; CH_RAW=""; KEEP_RAW_FILE="0"
                "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_FALLBACK} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
              fi
            else
              echo "${DTF}: DAB ${CH}: no-rewind retry recovered enough services; skipping long recapture" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            fi
          elif [ "${DABRAW_TOO_WEAK}" = "1" ] && [ "${IS_FIXED_POSITION}" = "1" ] && [ ! -z "${CH_FREQ}" ]; then
            # Fixed position weak signal: recapture with FMLIST_SCAN_DAB_RAW_DURATION_SEC fallback and retry without rewind
            RETRY_RAW_DURATION="${FMLIST_SCAN_DAB_RAW_DURATION_SEC}"
            DTFRAW_RETRY="$(date -u "+%Y%m%dT%H%M%SZ")"
            _RETRY_W_MS=$((RETRY_RAW_DURATION * 1000))
            CH_RAW_RETRY="${rec_path}/DAB_${CH}_${DAB_EID}_${DTFRAW_RETRY}_${RETRY_RAW_DURATION}sec_temp.raw"
            NSMP_RETRY=$[ ${RETRY_RAW_DURATION} * 2048000 ]
            DABOPT_RAW_NOREWIND="$(echo " ${DABOPT_RAW_FOR_ANALYSIS} " | sed -E "s/[[:space:]]-X([[:space:]]|$)/ /g; s/[[:space:]]-Y([[:space:]]|$)/ /g; s/[[:space:]]-E[[:space:]]+[0-9]+/ -E 0/g; s/[[:space:]]-W [0-9]+/ -W ${_RETRY_W_MS}/g; s/[[:space:]]-A [0-9-]+/ -A -1/g; s/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/ /g")"  
            echo "${DTF}: DAB ${CH}: too weak signal; recapturing ${RETRY_RAW_DURATION}s and retrying without rewind" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            echo "rtl_sdr -f ${CH_FREQ} -s 2048000 -n ${NSMP_RETRY} ${FMLIST_DAB_RTLSDR_OPT} ${CH_RAW_RETRY}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            timeout -s SIGTERM -k 2 $[${RETRY_RAW_DURATION} + 3] rtl_sdr -f ${CH_FREQ} -s 2048000 -n ${NSMP_RETRY} ${FMLIST_DAB_RTLSDR_OPT} "${CH_RAW_RETRY}" >"${rec_path}/DAB_${CH}_rtl_retry.log" 2>&1
            RTL_RETRY_RC=$?
            if { [ ${RTL_RETRY_RC} -eq 0 ] || [ ${RTL_RETRY_RC} -eq 124 ]; } && [ -s "${CH_RAW_RETRY}" ]; then
              rm -f "${CH_RAW}" 2>/dev/null
              CH_RAW="${CH_RAW_RETRY}"
              echo "${DAB_RAW_BIN} -F ${CH_RAW} ${DABOPT_RAW_NOREWIND}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
              runDabRaw "${rec_path}/DAB_${CH}.log" "${rec_path}/DAB_${CH}_stderr.log" -F "${CH_RAW}" ${DABOPT_RAW_NOREWIND}
              sed -i -E "s/(,CSV_(AUDIO|ENSEMBLE|GPSCOOR|PACKET),\")[^\"]*(\")/\1${CH}\3/g" "${rec_path}/DAB_${CH}.log"
              DABRAW_CSV_ENS=$(grep -c ",CSV_ENSEMBLE," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
              DABRAW_CSV_AUD=$(grep -c ",CSV_AUDIO," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
              if [ ${DABRAW_CSV_ENS} -eq 0 ] && [ ${DABRAW_CSV_AUD} -eq 0 ]; then
                echo "${DTF}: DAB ${CH}: longer-clip retry produced no CSV; keeping discovery-only result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
                rm -f "${CH_RAW}" 2>/dev/null || true; CH_RAW=""; KEEP_RAW_FILE="0"
                "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_FALLBACK} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
              else
                DABRAW_LIST_LINES=$(grep -c "^LIST: SID " "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null || true)
                if [ -z "${DABRAW_LIST_LINES}" ]; then DABRAW_LIST_LINES=0; fi
                DABRAW_CRASHED="0"
                if grep -qi "terminate called without an active exception" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null; then
                  DABRAW_CRASHED="1"
                fi
                if [ "${DABRAW_CRASHED}" = "1" ] && [ ${DISC_NUM_SIDS} -ge 2 ] && [ ${DABRAW_LIST_LINES} -lt ${DISC_NUM_SIDS} ]; then
                  echo "${DTF}: DAB ${CH}: long-retry still incomplete (${DABRAW_LIST_LINES}/${DISC_NUM_SIDS}) after crash; keeping strict -D mode" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
                  rerunMissingServiceDetailsWithD "${CH}" "${CH_RAW}" "${DABOPT_RAW_NOREWIND}" "${DISC_NUM_SIDS}"
                fi
                echo "${DTF}: DAB ${CH}: longer-clip retry produced CSV; keeping dab-raw result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
              fi
            else
              echo "${DTF}: DAB ${CH}: longer-clip capture failed (rc=${RTL_RETRY_RC}); keeping discovery-only result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
              rm -f "${CH_RAW_RETRY}" 2>/dev/null
              rm -f "${CH_RAW}" 2>/dev/null || true; CH_RAW=""; KEEP_RAW_FILE="0"
              "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_FALLBACK} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
            fi
          elif [ "${DABRAW_TOO_WEAK}" = "1" ]; then
            # Mobile or no freq: retry without rewind on existing clip
            _NOREWIND_W=$((${RAW_DURATION_SEC:-15} * 1000))
            DABOPT_RAW_NOREWIND="$(echo " ${DABOPT_RAW_FOR_ANALYSIS} " | sed -E "s/[[:space:]]-X([[:space:]]|$)/ /g; s/[[:space:]]-Y([[:space:]]|$)/ /g; s/[[:space:]]-E[[:space:]]+[0-9]+/ -E 0/g; s/[[:space:]]-W [0-9]+/ -W ${_NOREWIND_W}/g; s/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/ /g")"
            echo "${DTF}: DAB ${CH}: too weak signal; retrying without rewind on existing clip" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            echo "${DAB_RAW_BIN} -F ${CH_RAW} ${DABOPT_RAW_NOREWIND}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            runDabRaw "${rec_path}/DAB_${CH}.log" "${rec_path}/DAB_${CH}_stderr.log" -F "${CH_RAW}" ${DABOPT_RAW_NOREWIND}
            sed -i -E "s/(,CSV_(AUDIO|ENSEMBLE|GPSCOOR|PACKET),\")[^\"]*(\")/\1${CH}\3/g" "${rec_path}/DAB_${CH}.log"
            DABRAW_CSV_ENS=$(grep -c ",CSV_ENSEMBLE," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
            DABRAW_CSV_AUD=$(grep -c ",CSV_AUDIO," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
            if [ ${DABRAW_CSV_ENS} -eq 0 ] && [ ${DABRAW_CSV_AUD} -eq 0 ]; then
              echo "${DTF}: DAB ${CH}: no-rewind retry produced no CSV; keeping discovery-only result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
              "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_FALLBACK} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
            else
              echo "${DTF}: DAB ${CH}: no-rewind retry produced CSV; keeping dab-raw result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            fi
          elif [ "${IS_FIXED_POSITION}" = "1" ] && [ ${DABRAW_RC} -eq 0 ] && \
               [ ${DABRAW_CSV_AUD} -gt 0 ] && [ ${DISC_NUM_SIDS} -ge 3 ] && \
            [ ${DABRAW_SERVICE_EVIDENCE} -lt ${DISC_NUM_SIDS} ] && [ ! -z "${CH_FREQ}" ]; then
            # Succeeded but incomplete: some services lacked FIG 0/8 component links due to
            # weak FIC quality. Recapture a longer clip to collect more FIC block repetitions.
            RETRY_RAW_DURATION=$((RAW_DURATION_SEC * 2))
            if [ ${RETRY_RAW_DURATION} -gt 60 ]; then RETRY_RAW_DURATION=60; fi
            _RETRY_W_MS=$((RETRY_RAW_DURATION * 1000))
            DTFRAW_RETRY="$(date -u "+%Y%m%dT%H%M%SZ")"
            CH_RAW_RETRY="${rec_path}/DAB_${CH}_${DAB_EID}_${DTFRAW_RETRY}_${RETRY_RAW_DURATION}sec_temp.raw"
            NSMP_RETRY=$[ ${RETRY_RAW_DURATION} * 2048000 ]
            DABOPT_RAW_RETRY="$(echo " ${DABOPT_RAW_FOR_ANALYSIS} " | sed -E "s/[[:space:]]-X([[:space:]]|$)/ /g; s/[[:space:]]-Y([[:space:]]|$)/ /g; s/[[:space:]]-E[[:space:]]+[0-9]+/ -E 0/g; s/[[:space:]]-W [0-9]+/ -W ${_RETRY_W_MS}/g; s/[[:space:]]-A [0-9-]+/ -A -1/g; s/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/ /g")"
            echo "${DTF}: DAB ${CH}: incomplete (${DABRAW_SERVICE_EVIDENCE}/${DISC_NUM_SIDS} services; csv=${DABRAW_CSV_SID_UNIQ}, list=${DABRAW_LIST_LINES}); recapturing ${RETRY_RAW_DURATION}s for more FIC coverage" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            rm -f "${CH_RAW}" 2>/dev/null || true
            echo "rtl_sdr -f ${CH_FREQ} -s 2048000 -n ${NSMP_RETRY} ${FMLIST_DAB_RTLSDR_OPT} ${CH_RAW_RETRY}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
            timeout -s SIGTERM -k 2 $[${RETRY_RAW_DURATION} + 3] rtl_sdr -f ${CH_FREQ} -s 2048000 -n ${NSMP_RETRY} ${FMLIST_DAB_RTLSDR_OPT} "${CH_RAW_RETRY}" >"${rec_path}/DAB_${CH}_rtl_retry.log" 2>&1
            RTL_RETRY_RC=$?
            if { [ ${RTL_RETRY_RC} -eq 0 ] || [ ${RTL_RETRY_RC} -eq 124 ]; } && [ -s "${CH_RAW_RETRY}" ]; then
              CH_RAW="${CH_RAW_RETRY}"
              echo "${DAB_RAW_BIN} -F ${CH_RAW} ${DABOPT_RAW_RETRY}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
              runDabRaw "${rec_path}/DAB_${CH}.log" "${rec_path}/DAB_${CH}_stderr.log" -F "${CH_RAW}" ${DABOPT_RAW_RETRY}
              DABRAW_RC=$?
              sed -i -E "s/(,CSV_(AUDIO|ENSEMBLE|GPSCOOR|PACKET),\")[^\"]*(\")/\1${CH}\3/g" "${rec_path}/DAB_${CH}.log"
              DABRAW_CSV_ENS=$(grep -c ",CSV_ENSEMBLE," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
              DABRAW_CSV_AUD=$(grep -c ",CSV_AUDIO," "${rec_path}/DAB_${CH}.log" 2>/dev/null)
              if [ ${DABRAW_CSV_ENS} -eq 0 ] && [ ${DABRAW_CSV_AUD} -eq 0 ]; then
                echo "${DTF}: DAB ${CH}: longer retry produced no CSV; keeping discovery-only result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
                rm -f "${CH_RAW}" 2>/dev/null || true; CH_RAW=""; KEEP_RAW_FILE="0"
                "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT_FALLBACK} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
              else
                DABRAW_LIST_LINES=$(grep -c "^LIST: SID " "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null || true)
                if [ -z "${DABRAW_LIST_LINES}" ]; then DABRAW_LIST_LINES=0; fi
                echo "${DTF}: DAB ${CH}: longer retry: ${DABRAW_LIST_LINES}/${DISC_NUM_SIDS} services found" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
              fi
            else
              echo "${DTF}: DAB ${CH}: longer-clip capture failed (rc=${RTL_RETRY_RC}); keeping initial result" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
              rm -f "${CH_RAW_RETRY}" 2>/dev/null
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

    # Keep the main channel pass authoritative.
    # Per-SID recovery is only done in explicit failure/incomplete paths above.

    # If detailed/raw path ended with empty logs but discovery had an ensemble,
    # restore discovery evidence to avoid dropping the channel as NO station.
    FINAL_CSV_CNT=$(grep -c ",CSV_ENSEMBLE,\|,CSV_AUDIO,\|,CSV_PACKET," "${rec_path}/DAB_${CH}.log" 2>/dev/null || true)
    FINAL_NE_CNT=$(grep -c "ensemblenameHandler: .* is recognized" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null || true)
    FINAL_NP_CNT=$(grep -c "^programnameHandler:.* is part of the ensemble" "${rec_path}/DAB_${CH}_stderr.log" 2>/dev/null || true)
    if [ -z "${FINAL_CSV_CNT}" ]; then FINAL_CSV_CNT=0; fi
    if [ -z "${FINAL_NE_CNT}" ]; then FINAL_NE_CNT=0; fi
    if [ -z "${FINAL_NP_CNT}" ]; then FINAL_NP_CNT=0; fi
    if [ ${FINAL_CSV_CNT} -eq 0 ] && [ ${FINAL_NE_CNT} -eq 0 ] && [ ${FINAL_NP_CNT} -eq 0 ] \
      && [ ! -z "${DAB_ENS_KEY}" ] && [ -s "${DISCOVERY_LOG_SNAPSHOT}" ] && [ -s "${DISCOVERY_ERR_SNAPSHOT}" ]; then
      cp -f "${DISCOVERY_LOG_SNAPSHOT}" "${rec_path}/DAB_${CH}.log"
      cp -f "${DISCOVERY_ERR_SNAPSHOT}" "${rec_path}/DAB_${CH}_stderr.log"
      echo "${DTF}: DAB ${CH}: restored discovery snapshot after empty detailed/raw outcome; keeping ensemble evidence (${DAB_ENS_KEY})" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    fi

    synthesizeWeakAudioRowsFromProgramList "${CH}" "${rec_path}/DAB_${CH}.log" "${rec_path}/DAB_${CH}_stderr.log"
    normalizeServiceSpecificTooWeakAudio "${CH}" "${rec_path}/DAB_${CH}.log"

    rm -f "${DISCOVERY_LOG_SNAPSHOT}" "${DISCOVERY_ERR_SNAPSHOT}" 2>/dev/null || true

    process_dab_channel_results "${CH}" "${CH_RAW}" "${DTFFIC}" "${KEEP_RAW_FILE}" "${DISC_ENS_LONG}" "${DISC_ENS_SHORT}"
  else
    "${DAB_RTLSDR_BIN}" -C ${CH} ${DABOPT} 1>"${rec_path}/DAB_${CH}.log" 2>"${rec_path}/DAB_${CH}_stderr.log"
    process_dab_channel_results "${CH}" "" "${DTFFIC}" "0" "" ""
  fi
done

if [ -d /sys/class/thermal/thermal_zone0 ]; then
  echo -e "$(date -u "+%Y-%m-%dT%T Z"): Temperature at scanDAB.sh after dab-rtlsdr: $(cat /sys/class/thermal/thermal_zone*/temp | awk '{printf "%.1f°C ", $1/1000}')" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
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

