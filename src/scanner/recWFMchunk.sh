#!/bin/bash

source "$HOME/.config/fmlist_scan/config"
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

chan="$1"
durs="$2"
shift
shift

# R820T tuner bandwidths in kHz: 350, 450, 550, 700, 900, 1200, 1450, 1550, 1600, 1700, 1800, 1900, 1950, 2050, 2080
# RTL_BW_OPTs measured with white noise generator at ~100 MHz to be still flat (< 1 dB to next missing channel, if possible)
#mpxsrate_chunkbw_factor="10"; RTL_BW_OPT="-w 1800000"    # +/-750000 Hz, N = 16, chunkbw = 1710 kHz

BWSTR=""
if   [ "$1" = "bw2"  ]; then  OVERRIDE_BW_FAC="2"  ; OVERRIDE_BW_OPT="-w 450000"  ; BWSTR="_450k" ; shift
elif [ "$1" = "bw3"  ]; then  OVERRIDE_BW_FAC="3"  ; OVERRIDE_BW_OPT="-w 550000"  ; BWSTR="_550k" ; shift
elif [ "$1" = "bw4"  ]; then  OVERRIDE_BW_FAC="4"  ; OVERRIDE_BW_OPT="-w 900000"  ; BWSTR="_900k" ; shift
elif [ "$1" = "bw5"  ]; then  OVERRIDE_BW_FAC="5"  ; OVERRIDE_BW_OPT="-w 1200000" ; BWSTR="_1200k" ; shift
elif [ "$1" = "bw6"  ]; then  OVERRIDE_BW_FAC="6"  ; OVERRIDE_BW_OPT="-w 1200000" ; BWSTR="_1200k" ; shift
elif [ "$1" = "bw7"  ]; then  OVERRIDE_BW_FAC="7"  ; OVERRIDE_BW_OPT="-w 1200000" ; BWSTR="_1200k" ; shift
elif [ "$1" = "bw8"  ]; then  OVERRIDE_BW_FAC="8"  ; OVERRIDE_BW_OPT="-w 1450000" ; BWSTR="_1450k" ; shift
elif [ "$1" = "bw9"  ]; then  OVERRIDE_BW_FAC="9"  ; OVERRIDE_BW_OPT="-w 1600000" ; BWSTR="_1600k" ; shift
elif [ "$1" = "bw10" ]; then  OVERRIDE_BW_FAC="10" ; OVERRIDE_BW_OPT="-w 1800000" ; BWSTR="_1800k" ; shift
elif [ "$1" = "bw11" ]; then  OVERRIDE_BW_FAC="11" ; OVERRIDE_BW_OPT="-w 2080000" ; BWSTR="_2090k" ; shift
fi

fext="raw"
gainval=""
if [ "$1" = "-H" ]; then
  fext="wav"
  if [ "$2" = "-g" ]; then
    gainval="$3"
  fi
else
  if [ "$1" = "-g" ]; then
    gainval="$2"
  fi
fi


GAINSTR=""
if   [ "${gainval}" = "0.9"  ]; then  GAINSTR="-g0.9"
elif [ "${gainval}" = "1.4"  ]; then  GAINSTR="-g1.4"
elif [ "${gainval}" = "2.7"  ]; then  GAINSTR="-g2.7"
elif [ "${gainval}" = "3.7"  ]; then  GAINSTR="-g3.7"
elif [ "${gainval}" = "7.7"  ]; then  GAINSTR="-g7.7"
elif [ "${gainval}" = "8.7"  ]; then  GAINSTR="-g8.7"
elif [ "${gainval}" = "12.5" ]; then  GAINSTR="-g12.5"
elif [ "${gainval}" = "14.4" ]; then  GAINSTR="-g14.4"
elif [ "${gainval}" = "15.7" ]; then  GAINSTR="-g15.7"
elif [ "${gainval}" = "16.6" ]; then  GAINSTR="-g16.6"
elif [ "${gainval}" = "19.7" ]; then  GAINSTR="-g19.7"
elif [ "${gainval}" = "20.7" ]; then  GAINSTR="-g20.7"
elif [ "${gainval}" = "22.9" ]; then  GAINSTR="-g22.9"
elif [ "${gainval}" = "25.4" ]; then  GAINSTR="-g25.4"
elif [ "${gainval}" = "28.0" ]; then  GAINSTR="-g28.0"
elif [ "${gainval}" = "29.7" ]; then  GAINSTR="-g29.7"
elif [ "${gainval}" = "32.8" ]; then  GAINSTR="-g32.8"
elif [ "${gainval}" = "33.8" ]; then  GAINSTR="-g33.8"
elif [ "${gainval}" = "36.4" ]; then  GAINSTR="-g36.4"
elif [ "${gainval}" = "37.2" ]; then  GAINSTR="-g37.2"
elif [ "${gainval}" = "38.6" ]; then  GAINSTR="-g38.6"
elif [ "${gainval}" = "40.2" ]; then  GAINSTR="-g40.2"
elif [ "${gainval}" = "42.1" ]; then  GAINSTR="-g42.1"
elif [ "${gainval}" = "43.4" ]; then  GAINSTR="-g43.4"
elif [ "${gainval}" = "43.9" ]; then  GAINSTR="-g43.9"
elif [ "${gainval}" = "44.5" ]; then  GAINSTR="-g45.5"
elif [ "${gainval}" = "48.0" ]; then  GAINSTR="-g48.0"
elif [ "${gainval}" = "49.6" ]; then  GAINSTR="-g49.6"
elif [ "${gainval}" = "1"  ]; then  GAINSTR="-g0.9"
elif [ "${gainval}" = "3"  ]; then  GAINSTR="-g2.7"
elif [ "${gainval}" = "4"  ]; then  GAINSTR="-g3.7"
elif [ "${gainval}" = "8"  ]; then  GAINSTR="-g7.7"
elif [ "${gainval}" = "9"  ]; then  GAINSTR="-g8.7"
elif [ "${gainval}" = "13" ]; then  GAINSTR="-g12.5"
elif [ "${gainval}" = "14" ]; then  GAINSTR="-g14.4"
elif [ "${gainval}" = "16" ]; then  GAINSTR="-g15.7"
elif [ "${gainval}" = "17" ]; then  GAINSTR="-g16.6"
elif [ "${gainval}" = "20" ]; then  GAINSTR="-g19.7"
elif [ "${gainval}" = "21" ]; then  GAINSTR="-g20.7"
elif [ "${gainval}" = "23" ]; then  GAINSTR="-g22.9"
elif [ "${gainval}" = "25" ]; then  GAINSTR="-g25.4"
elif [ "${gainval}" = "28" ]; then  GAINSTR="-g28.0"
elif [ "${gainval}" = "30" ]; then  GAINSTR="-g29.7"
elif [ "${gainval}" = "33" ]; then  GAINSTR="-g32.8"
elif [ "${gainval}" = "34" ]; then  GAINSTR="-g33.8"
elif [ "${gainval}" = "36" ]; then  GAINSTR="-g36.4"
elif [ "${gainval}" = "37" ]; then  GAINSTR="-g37.2"
elif [ "${gainval}" = "39" ]; then  GAINSTR="-g38.6"
elif [ "${gainval}" = "40" ]; then  GAINSTR="-g40.2"
elif [ "${gainval}" = "42" ]; then  GAINSTR="-g42.1"
elif [ "${gainval}" = "43" ]; then  GAINSTR="-g43.4"
elif [ "${gainval}" = "44" ]; then  GAINSTR="-g43.9"
elif [ "${gainval}" = "45" ]; then  GAINSTR="-g45.5"
elif [ "${gainval}" = "48" ]; then  GAINSTR="-g48.0"
elif [ "${gainval}" = "50" ]; then  GAINSTR="-g49.6"
fi

if [ -z "${chan}" ] || [ "${chan}" = "-h" ] || [ "${chan}" = "--help" ] || [ -z "${durs}" ]; then
  echo "usage: $0 <frequency in MHz> <duration in seconds> [bw2|bw3|..|bw11] [-H] [<additional options to rtl_sdr>]"
  exit 0
fi

if [ -f "${FMLIST_SCAN_RAM_DIR}/scanLoopBgRunning" ]; then
  echo "scanLoop is running! stop with 'stopBgScanLoop.sh' for recording"
  exit 10
fi

freq="${chan}e6"

DTFREC="$(date -u "+%Y-%m-%dT%Hh%Mm%SZ")"

source "$HOME/.config/fmlist_scan/fmscan.inc"

# R820T tuner bandwidths in kHz: 350, 450, 550, 700, 900, 1200, 1450, 1550, 1600, 1700, 1800, 1900, 1950, 2050, 2080
# RTL_BW_OPTs measured with white noise generator at ~100 MHz to be still flat (< 1 dB to next missing channel, if possible)
#mpxsrate_chunkbw_factor="10"; RTL_BW_OPT="-w 1800000"    # +/-750000 Hz, N = 16, chunkbw = 1710 kHz

if [ ! -z "${OVERRIDE_BW_FAC}" ]; then
  mpxsrate_chunkbw_factor="${OVERRIDE_BW_FAC}"
  RTL_BW_OPT="${OVERRIDE_BW_OPT}"
fi

pilotfreq="19000"
rdsfreq="$[ $pilotfreq * 3 ]"   # rdsfreq = 19 * 3 = 57 kHz
mpxsrate="$[ $rdsfreq * 3 ]"    # mpxsrate = 57 * 3 = 171 kHz
chunksrate="$[ $mpxsrate * $chunk2mpx_dec ]"        # chunksrate = 171 * 14 = 2394 kHz
chunkbw="$[ $mpxsrate * $mpxsrate_chunkbw_factor ]" # chunkbw = 171 * 10 = 1710 kHz
chunknumsmp="$[ ${durs} * $chunksrate ]"

if [ -z "$chunknumsmp" ]; then
  echo "error calculating number of samples to record from duration '${durs}' in seconds"
  exit 0
fi

$HOME/bin/gpstime.sh single
if [ -f "${FMLIST_SCAN_RAM_DIR}/gpscoor.inc" ]; then
  GPSV="$( ( flock -s 213 ; cat "${FMLIST_SCAN_RAM_DIR}/gpscoor.inc" 2>/dev/null ) 213>${FMLIST_SCAN_RAM_DIR}/gps.lock )"
  echo "${GPSV}" >${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
  source ${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
  rm ${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
  FN="FM-${chan}M_${DTFREC}_${chunksrate}Hz_PCM8IQ_${GPSFN}${BWSTR}${GAINSTR}.${fext}"
else
  FN="FM-${chan}M_${DTFREC}_${chunksrate}Hz_PCM8IQ${BWSTR}${GAINSTR}.${fext}"
fi

FPN="${FMLIST_SCAN_RAM_DIR}/${FN}"
echo "FN is  ${FN}"
echo "FPN is ${FPN}"
echo "running rtl_sdr -f ${freq} -s ${chunksrate} -n ${chunknumsmp} ${RTLSDR_OPT} ${RTL_BW_OPT} $@ ${FPN} .."
rtl_sdr -f ${freq} -s ${chunksrate} -n ${chunknumsmp} ${RTLSDR_OPT} ${RTL_BW_OPT} "$@" "${FPN}"

echo "recorded file is: $( ls -lh "${FPN}" )"


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

if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/IQrecords" ]; then
  mkdir -p "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/IQrecords"
fi

echo "copying to ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/IQrecords/ .."
cp "${FPN}" "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/IQrecords/"
echo "finished."
if [ -f "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/IQrecords/${FN}" ]; then
  rm "${FPN}"
fi

