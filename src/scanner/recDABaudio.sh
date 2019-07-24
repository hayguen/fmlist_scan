#!/bin/bash

source "$HOME/.config/fmlist_scan/config"
source "$HOME/.config/fmlist_scan/dabscan.inc"

function usage() {
  echo "usage: $0 <#minutes> <filenameId> <channel> [<additional options to dab-rtlsdr>]"
  echo " additional options - as in dab-rtlsdr, e.g. -P or -S:"
  LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}" dab-rtlsdr -h
}

if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

durationMinutes="$1"
fnID="$2"
chan="$3"

if [ -z "${durationMinutes}" ] || [ -z "${chan}" ] || [ "${durationMinutes}" = "-h" ] || [ "${durationMinutes}" = "--help" ]; then
  usage
  exit 0
fi

shift
shift
durationSeconds=$[ ${durationMinutes} * 60 ]

if [ -z "${durationSeconds}" ]; then
  usage
  exit 0
fi


if [ -f "${FMLIST_SCAN_RAM_DIR}/scanLoopBgRunning" ]; then
  echo "scanLoop is running! stop with 'stopBgScanLoop.sh' for recording"
  exit 10
fi

if [ -z "${durationSeconds}" ]; then
  echo "invalid duration in argument 1"
  exit 0
fi


if [ -z "${chan}" ]; then
  echo "invalid dab channel in argument 2"
  exit 0
fi

durationClose=$[ ${durationSeconds} + 20 ]
durationKill=$[ ${durationSeconds} + 30 ]
DTFREC="$(date -u "+%Y-%m-%dT%Hh%Mm%SZ")"
FN="DAB-${chan}_${DTFREC}_${fnID}.wav"
FL="DAB-${chan}_${DTFREC}_${fnID}.log"
echo "starting   dab-rtlsdr ${DABLISTENOPT} -n ${durationSeconds} -w ${FMLIST_SCAN_RAM_DIR}/${FN} -C $@"

# save DAB images in RAM
mkdir -p "${FMLIST_SCAN_RAM_DIR}/DAB-${chan}_${DTFREC}_${fnID}"
cd "${FMLIST_SCAN_RAM_DIR}/DAB-${chan}_${DTFREC}_${fnID}"

LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}" timeout -s SIGKILL -k ${durationKill} ${durationClose} \
  dab-rtlsdr ${DABLISTENOPT} -n ${durationSeconds} -w "${FN}" -C "$@" 2>&1 | tee ${FL}

cd "${FMLIST_SCAN_RAM_DIR}"

# 48 kHz x 2 ch x 2 bytes/ch = 192000 B/sec
# 192 B/sec * 60 sec/min = 11250 kB  in 1 min
# 192 B/sec * 60 sec/min * 15 min = 168750 kB ~= 165 MB in 15 min


MNTC=$( mount | grep -c ${FMLIST_SCAN_RESULT_DIR} )
if [ $MNTC -eq 0 ] && [ ${FMLIST_SCAN_MOUNT} -eq 1 ]; then
  mount ${FMLIST_SCAN_RESULT_DIR}
  MNTC=$( mount | grep -c ${FMLIST_SCAN_RESULT_DIR} )
  if [ $MNTC -eq 0 ]; then
    echo "Error: Device (USB memory stick) is not available on ${FMLIST_SCAN_RESULT_DIR} !"
    exit 0
  fi
fi

if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner" ]; then
  mkdir -p "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner"
fi

if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/DABaudio" ]; then
  mkdir -p "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/DABaudio"
fi

echo "copying to ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/DABaudio/ .."

cp -r "${FMLIST_SCAN_RAM_DIR}/DAB-${chan}_${DTFREC}_${fnID}" "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/DABaudio/"
echo "finished."
rm -rf "${FMLIST_SCAN_RAM_DIR}/DAB-${chan}_${DTFREC}_${fnID}"
