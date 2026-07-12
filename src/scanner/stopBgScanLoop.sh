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

# Kill any running TEF scan processes (Python) to interrupt scanning
pgrep -f "python.*scanFM_tef" >/dev/null 2>&1 && {
  echo "Sending SIGTERM to running scanFM_tef.py processes..."
  pkill -TERM -f "python.*scanFM_tef" 2>/dev/null
  sleep 0.5
  # Force kill if still running
  pgrep -f "python.*scanFM_tef" >/dev/null 2>&1 && {
    echo "Force killing scanFM_tef.py processes..."
    pkill -KILL -f "python.*scanFM_tef" 2>/dev/null
  }
}

# Also kill any redsea processes that might be decoding RDS
pgrep -f "redsea" >/dev/null 2>&1 && {
  pkill -TERM -f "redsea" 2>/dev/null
  sleep 0.2
  pgrep -f "redsea" >/dev/null 2>&1 && {
    pkill -KILL -f "redsea" 2>/dev/null
  }
}

stopGpsLoop.sh silent

if [ "$1" = "wait" ]; then
  shift
  waitScreenTermination.sh scanLoopBg "$@"
fi

