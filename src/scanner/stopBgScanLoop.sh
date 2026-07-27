#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

# new desired state
rm -f ${FMLIST_SCAN_RAM_DIR}/scanLoopBgRunning

if [ ! -z "$1" ] && [ ! "$1" = "abort" ] && [ ! "$1" = "wait" ]; then
  echo "unrecognized option '$1': expected 'abort' or 'wait'"
fi

if [ "$1" = "abort" ]; then
  shift
  touch "${FMLIST_SCAN_RAM_DIR}/abortScanLoop"
fi

touch "${FMLIST_SCAN_RAM_DIR}/stopScanLoop"

kill_matching_processes() {
  local pattern="$1"
  local label="$2"
  if pgrep -f "${pattern}" >/dev/null 2>&1; then
    echo "Stopping ${label} ..."
    pkill -TERM -f "${pattern}" 2>/dev/null || true
    sleep 0.5
    if pgrep -f "${pattern}" >/dev/null 2>&1; then
      echo "Force killing ${label} ..."
      pkill -KILL -f "${pattern}" 2>/dev/null || true
    fi
  fi
}

# Stop loop controller and all active scan/analyzer workers.
kill_matching_processes "scanLoop.sh|scanDAB.sh|scanFM.sh|python.*scanFM_tef" "scan loop workers"
kill_matching_processes "dab-raw|dab-rtlsdr|rtl_sdr|prescanDAB" "DAB analyzers/captures"
kill_matching_processes "redsea|csdr|kal" "decoder helper processes"

stopGpsLoop.sh silent

if [ "$1" = "wait" ]; then
  shift
  waitScreenTermination.sh scanLoopBg "$@"
fi

