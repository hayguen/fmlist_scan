#!/bin/bash

source "$HOME/.config/fmlist_scan/config"
source "$HOME/.config/fmlist_scan/dabscan.inc"

function usage() {
  echo "usage: $0 <#minutes> <filenameId> <channel> [<additional options to dab-rtlsdr>]"
  echo "  you might need to increase max. ramdisk size: sudo mount -o remount,size=600M /dev/shm"
  echo " additional options - as in eti-cmdline, e.g. -P or -S:"
  LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}" eti-cmdline-rtlsdr -h
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

durationClose=$[ ${durationSeconds} + 2 ]
durationKill=$[ ${durationSeconds} + 10 ]
DTFREC="$(date -u "+%Y-%m-%dT%Hh%Mm%SZ")"
FN="DAB-${chan}_${DTFREC}_${fnID}.eti"
FL="DAB-${chan}_${DTFREC}_${fnID}.log"
#echo "starting   eti-cmdline-rtlsdr ${DABLISTENOPT} -n ${durationSeconds} -w ${FMLIST_SCAN_RAM_DIR}/${FN} -C $@"
echo "starting   eti-cmdline-rtlsdr -Q -P 4 -O ${FMLIST_SCAN_RAM_DIR}/${FN} -C $@"

#$ eti-cmdline-rtlsdr -h
# general eti-cmdline-xxx options are
#
#   -P number    number of parallel threads for handling subchannels   -D number   time (in seconds) to look for a DAB ensemble
#   -M mode     Mode to be used    -B Band     select DAB Band (default: BAND_III, or L_BAND)
#   -C channel  DAB channel to be used (5A ... 13F resp. LA ... LP)
#   -O filename write output into a file (instead of stdout)
#   -R filename (if configured) dump to an *.sdr file
#   -S          be silent during processing
#   -h          show options and quit
#   -G number gain setting, depending on the version of the stick
#   -p number ppm setting
#   -Q autogain on


# save DAB images in RAM
mkdir -p "${FMLIST_SCAN_RAM_DIR}/DAB-${chan}_${DTFREC}_${fnID}"
cd "${FMLIST_SCAN_RAM_DIR}/DAB-${chan}_${DTFREC}_${fnID}"

LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}" timeout -v -s SIGTERM -k ${durationKill} ${durationClose} \
  eti-cmdline-rtlsdr -Q -P 4 -O "${FN}" -C "$@" 2>&1 | tee ${FL}

# eti-cmdline-rtlsdr ${DABLISTENOPT} -O "${FN}" -C "$@" 2>&1 | tee ${FL}

cd "${FMLIST_SCAN_RAM_DIR}"

# 2048 kBit/sec

source /home/${FMLIST_SCAN_USER}/bin/scanner_mount_result_dir.sh.inc

if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/DABeti" ]; then
  mkdir -p "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/DABeti"
fi

echo "copying to ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/DABeti/ .."

cp -r "${FMLIST_SCAN_RAM_DIR}/DAB-${chan}_${DTFREC}_${fnID}" "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/DABeti/"
echo "finished."
rm -rf "${FMLIST_SCAN_RAM_DIR}/DAB-${chan}_${DTFREC}_${fnID}"
