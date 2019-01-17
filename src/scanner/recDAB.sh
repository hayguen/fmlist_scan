#!/bin/bash

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

source "$HOME/.config/fmlist_scan/config"
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

chan="$1"
durs="$2"
shift
shift

if [ -z "${chan}" ] || [ "${chan}" = "-h" ] || [ "${chan}" = "--help" ] || [ -z "${durs}" ]; then
  echo "usage: $0 <channel> <duration in seconds> [<additional options to rtl_sdr>]"
  exit 0
fi

if [ -f "${FMLIST_SCAN_RAM_DIR}/scanLoopBgRunning" ]; then
  echo "scanLoop is running! stop with 'stopBgScanLoop.sh' for recording"
  exit 10
fi

freq="$( chanFreq "$chan" )"
if [ -z "${freq}" ]; then
  echo "invalid dab channel in argument 1"
  exit 0
fi

DTFREC="$(date -u "+%Y-%m-%dT%Hh%Mm%SZ")"

if [ -z "${FMLIST_DAB_RTLSDR_DEV}" ]; then
  FMLIST_DAB_RTLSDR_OPT=""
else
  FMLIST_DAB_RTLSDR_OPT="-d ${FMLIST_DAB_RTLSDR_DEV}"
fi

NSMP="$[ ${durs} * 2048000 ]"
if [ -z "$NSMP" ]; then
  echo "error calculating number of samples to record from duration '${durs}' in seconds"
  exit 0
fi

$HOME/bin/gpstime.sh single
if [ -f "${FMLIST_SCAN_RAM_DIR}/gpscoor.inc" ]; then
  GPSV="$( ( flock -s 213 ; cat "${FMLIST_SCAN_RAM_DIR}/gpscoor.inc" 2>/dev/null ) 213>gps.lock )"
  echo "${GPSV}" >${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
  source ${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
  rm ${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
  FN="DAB-${chan}_${DTFREC}_2048000Hz_PCM8IQ_${GPSFN}.raw"
else
  FN="DAB-${chan}_${DTFREC}_2048000Hz_PCM8IQ.raw"
fi

FPN="${FMLIST_SCAN_RAM_DIR}/${FN}"
echo "running rtl_sdr -f ${freq} -s 2048000 -n ${NSMP} ${FMLIST_DAB_RTLSDR_OPT} $@ ${FPN} .."
rtl_sdr -f ${freq} -s 2048000 -n ${NSMP} ${FMLIST_DAB_RTLSDR_OPT} "$@" "${FPN}"

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

