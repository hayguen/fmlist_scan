#!/bin/bash

source $HOME/.config/fmlist_scan/config

if [ "${FMLIST_SCAN_DAB}" == "0" ] || [ "${FMLIST_SCAN_DAB}" == "OFF" ]; then
  echo "DAB scan is deactivated with FMLIST_SCAN_DAB=${FMLIST_SCAN_DAB} in $HOME/.config/fmlist_scan/config"
  exit 0
fi


DTF="$(date -u "+%Y-%m-%dT%T.%N Z")"
DTFREC="$(date -u "+%Y-%m-%dT%H%M%S")"
TBEG="$(date -u +%s)"

rec_path="$HOME/ram/scan_${DTFREC}_DAB"
if [ ! -z "$1" ]; then
  rec_path="$HOME/ram/$1"
fi
if [ ! -d "${rec_path}" ]; then
  mkdir -p "${rec_path}"
fi

echo "DAB scan started at ${DTF}"
echo "DAB scan started at ${DTF}" >${rec_path}/scan_duration.txt

# get ${GPSSRC} for use in dabscan.inc
GPSVALS=$( ( flock -s 213 ; cat $HOME/ram/gpscoor.inc 2>/dev/null ) 213>gps.lock )
echo "${GPSVALS}" >$HOME/ram/gpsvals.inc
source $HOME/ram/gpsvals.inc
rm $HOME/ram/gpsvals.inc


if [ ! -f $HOME/ram/dabscan.inc ]; then
  if [ -f $HOME/.config/fmlist_scan/dabscan.inc ]; then
    cp $HOME/.config/fmlist_scan/dabscan.inc $HOME/ram/
    echo "copied scan parameters from $HOME/.config/fmlist_scan/dabscan.inc to $HOME/ram/dabscan.inc. edit this file for use with next scan."
  else
    cat - <<'EOF' >$HOME/ram/dabscan.inc
chanlist=dab_chanlist.txt
DABOPT="-Q -A 2000 -E 3 -W 5000"
EOF
    echo "wrote default scan parameters to $HOME/ram/dabscan.inc. edit this file for use with next scan."
  fi
fi
echo "reading scan parameters (chanlist, DABOPT) from $HOME/ram/dabscan.inc"
source $HOME/ram/dabscan.inc

if [ ! -z "${FMLIST_SCAN_PPM}" ]; then
  DABOPT="${DABOPT} -p ${FMLIST_SCAN_PPM}"
fi

chanpath="$HOME/ram/${chanlist}"
echo "chanpath=${chanpath}"
if [ ! -f "${chanpath}" ]; then
  echo "chanpath does not exist"
  if [ -f "${HOME}/.config/fmlist_scan/${chanlist}" ]; then
    echo "copying chanlist "${HOME}/.config/fmlist_scan/${chanlist}" to ${chanpath}"
    echo "copying chanlist "${HOME}/.config/fmlist_scan/${chanlist}" to ${chanpath}" >>$HOME/ram/scanner.log
    cp "${HOME}/.config/fmlist_scan/${chanlist}" "${chanpath}"
  else
    echo "Error: cannot find channellist file ${chanlist} configured in $HOME/ram/dabscan.inc !"
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

echo "" >>$HOME/ram/scanner.log


if [ ${FMLIST_SCAN_DAB_USE_PRESCAN} -ne 0 ]; then
  allchans=$( tr '\n' ',' <"${chanpath}" |sed 's#,$##g' )
  echo "running prescanDAB -W 64 -A 2 -C ${FMLIST_SCAN_DAB_MIN_AUTOCORR} -L ${allchans} .." >>$HOME/ram/scanner.log
  prescanDAB -W 64 -A 2 -C ${FMLIST_SCAN_DAB_MIN_AUTOCORR} -L "${allchans}" >$HOME/ram/dabscanout.inc
  echo "" >>$HOME/ram/scanner.log
  cat $HOME/ram/dabscanout.inc >>$HOME/ram/scanner.log
  . $HOME/ram/dabscanout.inc
  #echo ${#dabchannels[@]} ${dabchannels[@]}
else
  allchans=$( tr '\n' ' ' <"${chanpath}" )
  dabchannels=( ${allchans} )
fi

NUMFOUND=0
for CH in $(echo "${dabchannels[@]}") ; do

  if [ -f "$HOME/ram/stopScanLoop" ]; then
    break
  fi
  DTF="$(date -u "+%Y-%m-%dT%T.%N Z")"
  GPS="$($HOME/bin/get_gpstime.sh)"
  GPSV="$( ( flock -s 213 ; cat $HOME/ram/gpscoor.inc 2>/dev/null ) 213>gps.lock )"
  echo "$CH"
  echo "CHANNEL=\"${CH}\""    >"${rec_path}/DAB_$CH.inc"
  echo "CURRTIM=\"${DTF}\""  >>"${rec_path}/DAB_$CH.inc"
  echo "# last GPS:  ${GPS}" >>"${rec_path}/DAB_$CH.inc"
  echo "${GPSV}"             >>"${rec_path}/DAB_$CH.inc"
  echo "DAB_USE_PRESCAN=\"${FMLIST_SCAN_DAB_USE_PRESCAN}\""   >>"${rec_path}/DAB_$CH.inc"
  echo "DAB_MIN_AUTOCORR=\"${FMLIST_SCAN_DAB_MIN_AUTOCORR}\"" >>"${rec_path}/DAB_$CH.inc"

  if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
    echo -e "$(date -u "+%Y-%m-%dT%T Z"): Temperature at scanDAB.sh before dab-rtlsdr -C ${CH}: $(cat /sys/class/thermal/thermal_zone0/temp)" >>$HOME/ram/scanner.log
    echo "$(date -u +%s), $(cat /sys/class/thermal/thermal_zone0/temp)" >>$HOME/ram/cputemp.csv
  fi

  dab-rtlsdr -C $CH ${DABOPT} &>"${rec_path}/DAB_$CH.log"

  NP=$( cat "${rec_path}/DAB_$CH.log" | grep " is part of the ensemble" | grep -c "^programnameHandler:" )
  NE=$( cat "${rec_path}/DAB_$CH.log" | grep " is recognized" | grep -c "^ensemblenameHandler:" )
  echo "DAB_ENSEMBLE=\"${NE}\"" >>"${rec_path}/DAB_$CH.inc"
  echo "NUM_PROGRAMS=\"${NP}\"" >>"${rec_path}/DAB_$CH.inc"

  if [ $NP -eq 0 ]; then
    if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
      echo "${DTF}: DAB ${CH}: NO station" >>$HOME/ram/scanner.log
      mv "${rec_path}/DAB_${CH}.log" "${rec_path}/DAB_${CH}_no-station.log"
    else
      rm "${rec_path}/DAB_${CH}.log"
    fi
  else
    echo "DAB_$CH" >$HOME/ram/LAST
    NUMFOUND=$[ $NUMFOUND + 1 ]
    if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
      echo "${DTF}: DAB ${CH}: DETECTED station" >>$HOME/ram/scanner.log
    fi
    if [ ${FMLIST_SCAN_FOUND_PWMTONE} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
      scanToneFeedback.sh found
    fi
    if [ ${FMLIST_SCAN_FOUND_LEDPLAY} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
      sudo -E $HOME/bin/rpi3b_led_next.sh
    fi
  fi
done

if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
  echo -e "$(date -u "+%Y-%m-%dT%T Z"): Temperature at scanDAB.sh after dab-rtlsdr: $(cat /sys/class/thermal/thermal_zone0/temp)" >>$HOME/ram/scanner.log
  echo "$(date -u +%s), $(cat /sys/class/thermal/thermal_zone0/temp)" >>$HOME/ram/cputemp.csv
fi

TEND="$(date -u +%s)"
TDUR=$[ $TEND - $TBEG ]
DTF="$(date -u "+%Y-%m-%dT%T.%N Z")"
echo "DAB scan finished at ${DTF}"
echo "DAB scan finished at ${DTF}" >>${rec_path}/scan_duration.txt
echo "DAB scan duration ${TDUR} sec"
echo "DAB scan finished ${TDUR} sec" >>${rec_path}/scan_duration.txt
echo "DAB scan found ${NUMFOUND} stations"
echo "DAB scan found ${NUMFOUND} stations" >>${rec_path}/scan_duration.txt
if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
  echo "DAB scan finished at ${DTF}. Duration ${TDUR} sec." >>$HOME/ram/scanner.log
fi
if [ ${FMLIST_SCAN_RASPI} -ne 0 ] && [ ${FMLIST_SCAN_PWM_FEEDBACK} -ne 0 ]; then
  scanToneFeedback.sh dab ${NUMFOUND}
fi

