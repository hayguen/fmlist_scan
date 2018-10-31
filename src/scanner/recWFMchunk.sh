#!/bin/bash

source "$HOME/.config/fmlist_scan/config"
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

chan="$1"
durs="$2"

if [ -z "${chan}" ] || [ "${chan}" = "-h" ] || [ "${chan}" = "--help" ] || [ -z "${durs}" ]; then
  echo "usage: $0 <frequency in MHz> <duration in seconds>"
  exit 0
fi

freq="${chan}e6"

DTFREC="$(date -u "+%Y-%m-%dT%Hh%Mm%SZ")"

source "$HOME/.config/fmlist_scan/fmscan.inc"

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
  GPSV="$( ( flock -s 213 ; cat "${FMLIST_SCAN_RAM_DIR}/gpscoor.inc" 2>/dev/null ) 213>gps.lock )"
  echo "${GPSV}" >${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
  source ${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
  rm ${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
  FN="FM-${chan}M_${DTFREC}_${chunksrate}Hz_PCM8IQ_${GPSFN}.raw"
else
  FN="FM-${chan}M_${DTFREC}_${chunksrate}Hz_PCM8IQ.raw"
fi

FPN="${FMLIST_SCAN_RAM_DIR}/${FN}"
echo "running rtl_sdr -f ${freq} -s ${chunksrate} -n ${chunknumsmp} ${RTLSDR_OPT} ${RTL_BW_OPT} ${FPN} .."
rtl_sdr -f ${freq} -s ${chunksrate} -n ${chunknumsmp} ${RTLSDR_OPT} ${RTL_BW_OPT} "${FPN}"

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

if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/IQrecords" ]; then
  mkdir "${FMLIST_SCAN_RESULT_DIR}/IQrecords"
fi

echo "copying to ${FMLIST_SCAN_RESULT_DIR}/IQrecords/ .."
cp "${FPN}" "${FMLIST_SCAN_RESULT_DIR}/IQrecords/"
echo "finished."
if [ -f "${FMLIST_SCAN_RESULT_DIR}/IQrecords/${FN}" ]; then
  rm "${FPN}"
fi

