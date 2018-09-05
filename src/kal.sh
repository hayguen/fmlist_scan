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

echo "*** last PPM value ${FMLIST_SCAN_PPM}"
echo "*** last calibration channel ${FMLIST_SCAN_KAL_CH}"

if [ -z "${FMLIST_SCAN_KAL_CH}" ] || [ "$1" != "reuse" ]; then

  echo "last calibration channel empty or no option 'reuse'"
  echo "executing \"/usr/local/bin/kal -e ${FMLIST_SCAN_PPM} -s GSM900\"  to determine calibration channel"
  /usr/local/bin/kal -e ${FMLIST_SCAN_PPM} -s GSM900 |tee "${HOME}/ram/kal.log"

  echo "****"

  cat "${HOME}/ram/kal.log" |grep chan |awk  '/.*/ { print $7, $2; }' |sort -n |tail -n 1 >"${HOME}/ram/kal-gsm900-max.log"

  maxchan=`cat "${HOME}/ram/kal-gsm900-max.log" |awk '/.*/ { print $2; }'`
  maxpower=`cat "${HOME}/ram/kal-gsm900-max.log" |awk '/.*/ { print $1; }'`
  echo "*** max GSM900 channel is $maxchan with power $maxpower"
  FMLIST_SCAN_KAL_CH="${maxchan}"

  if [ ! -z "${FMLIST_SCAN_KAL_CH}" ]; then
    sed -i '/FMLIST_SCAN_KAL_CH=/d' "$HOME/.config/fmlist_scan/config"
    echo "export FMLIST_SCAN_KAL_CH=\"${FMLIST_SCAN_KAL_CH}\"" >>"$HOME/.config/fmlist_scan/config"
  fi
else
  echo "re-using last calibration channel ${FMLIST_SCAN_KAL_CH}"
fi

echo "executing /usr/local/bin/kal -e ${FMLIST_SCAN_PPM} -c ${FMLIST_SCAN_KAL_CH}"
/usr/local/bin/kal -e ${FMLIST_SCAN_PPM} -c ${FMLIST_SCAN_KAL_CH} |tee "${HOME}/ram/kal-channel.log"

NPPM=`cat "${HOME}/ram/kal-channel.log" |grep "absolute error" |awk  '/.*/ { print $4; }'`
echo "*** new PPM value $NPPM"
if [ ! -z "${NPPM}" ]; then
  sed -i '/FMLIST_SCAN_PPM=/d' "$HOME/.config/fmlist_scan/config"
  echo "export FMLIST_SCAN_PPM=\"${NPPM}\"  # ppm value of RTLSDR receiver" >>"$HOME/.config/fmlist_scan/config"
fi

