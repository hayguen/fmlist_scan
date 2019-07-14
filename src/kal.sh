#!/bin/bash

export LC_ALL=C
source $HOME/.config/fmlist_scan/config

if [ ! -z "${FMLIST_SCAN_PPM}" ]; then
  echo "read PPM value ${FMLIST_SCAN_PPM}"
else
  echo "no previous PPM"
  FMLIST_SCAN_PPM=0
fi

############################################

if [ -z "$1" ]; then
  echo "kal.sh [reuse] [GSM850|GSM-R|GSM900|EGSM|DCS|PCS] [<additional options to kal, e.g. -d 0>]"
  echo "continuing in 3 sec with default parameters: no reuse and GSM900"
  sleep 3
fi

OPT_REUSE=""
if [ "$1" = "reuse" ]; then
  OPT_REUSE="$1"
  shift
fi

SCANBAND="GSM900"
if [ "$1" = "GSM850" ] || [ "$1" = "GSM-R" ] || [ "$1" = "GSM900" ] || [ "$1" = "EGSM" ] || [ "$1" = "DCS" ] || [ "$1" = "PCS" ]; then
  SCANBAND="$1"
  shift
fi


echo "*** last PPM value ${FMLIST_SCAN_PPM}"
echo "*** last calibration channel ${FMLIST_SCAN_KAL_CH}"

RAMDIR="/dev/shm/$(whoami)_kal"
if [ ! -d "${RAMDIR}" ]; then
  mkdir "${RAMDIR}"
fi

if [ -z "${FMLIST_SCAN_KAL_CH}" ] || [ "${OPT_REUSE}" != "reuse" ]; then

  FMLIST_SCAN_KAL_CH=""

  echo "last calibration channel empty or no option 'reuse'"
  echo "executing \"/usr/local/bin/kal $* -e ${FMLIST_SCAN_PPM} -s ${SCANBAND}\"  to determine calibration channel"
  /usr/local/bin/kal $* -e ${FMLIST_SCAN_PPM} -s ${SCANBAND} |tee "${RAMDIR}/kal.log"

  echo "****"

  cat "${RAMDIR}/kal.log" |grep chan |awk  '/.*/ { print $7, $2; }' |sort -n |tail -n 1 >"${RAMDIR}/kal-${SCANBAND}-max.log"

  maxchan=$(cat "${RAMDIR}/kal-${SCANBAND}-max.log" |awk '/.*/ { print $2; }')
  maxpower=$(cat "${RAMDIR}/kal-${SCANBAND}-max.log" |awk '/.*/ { print $1; }')
  echo "*** max ${SCANBAND} channel is ${maxchan} with power ${maxpower}"
  FMLIST_SCAN_KAL_CH="${maxchan}"

  if [ ! -z "${FMLIST_SCAN_KAL_CH}" ]; then
    sed -i '/FMLIST_SCAN_KAL_CH=/d' "$HOME/.config/fmlist_scan/config"
    echo "export FMLIST_SCAN_KAL_CH=\"${FMLIST_SCAN_KAL_CH}\"" >>"$HOME/.config/fmlist_scan/config"
  else
    echo "ERROR determining channel on band ${SCANBAND}. Verify that antenna is suitable for given band .. or try other band !"
    exit 10
  fi
else
  echo "re-using last calibration channel ${FMLIST_SCAN_KAL_CH}"
fi

echo "executing /usr/local/bin/kal $* -e ${FMLIST_SCAN_PPM} -c ${FMLIST_SCAN_KAL_CH}"
/usr/local/bin/kal $* -e ${FMLIST_SCAN_PPM} -c ${FMLIST_SCAN_KAL_CH} |tee "${RAMDIR}/kal-channel.log"

NPPM=$(cat "${RAMDIR}/kal-channel.log" |grep "absolute error" |awk  '/.*/ { print $4; }')
echo "*** new PPM value ${NPPM}"
if [ ! -z "${NPPM}" ]; then
  sed -i '/FMLIST_SCAN_PPM=/d' "$HOME/.config/fmlist_scan/config"
  echo "export FMLIST_SCAN_PPM=\"${NPPM}\"  # ppm value of RTLSDR receiver" >>"$HOME/.config/fmlist_scan/config"
fi

