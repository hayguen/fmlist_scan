#!/bin/bash

source $HOME/.config/fmlist_scan

if [ "${FMLIST_SCAN_DAB}" == "0" ] || [ "${FMLIST_SCAN_DAB}" == "OFF" ]; then
  echo "DAB scan is deactivated with FMLIST_SCAN_DAB=${FMLIST_SCAN_DAB} in $HOME/.config/fmlist_scan"
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


if [ ! -f $HOME/ram/dabscan.inc ]; then
  if [ -f $HOME/.config/dabscan.inc ]; then
    cp $HOME/.config/dabscan.inc $HOME/ram/
    echo "copied scan parameters from $HOME/.config/dabscan.inc to $HOME/ram/dabscan.inc. edit this file for use with next scan."
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
  if [ -f "${HOME}/.config/${chanlist}" ]; then
    echo "copying chanlist "${HOME}/.config/${chanlist}" to ${chanpath}"
    echo "copying chanlist "${HOME}/.config/${chanlist}" to ${chanpath}" >>$HOME/ram/scanner.log
    cp "${HOME}/.config/${chanlist}" "${chanpath}"
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

allchans=$( tr '\n' ',' <"${chanpath}" |sed 's#,$##g' )


echo "running prescanDAB -W 64 -A 2 -L ${allchans} .." >>$HOME/ram/scanner.log
prescanDAB -W 64 -A 2 -L "${allchans}" >$HOME/ram/dabscanout.inc
echo "" >>$HOME/ram/scanner.log
cat $HOME/ram/dabscanout.inc >>$HOME/ram/scanner.log
. $HOME/ram/dabscanout.inc
#echo ${#dabchannels[@]} ${dabchannels[@]}

#cat "${chanpath}" | while read CH ; do
for CH in $(echo "${dabchannels[@]}") ; do

  if [ -f "$HOME/ram/stopScanLoop" ]; then
    break
  fi
  DTF="$(date -u "+%Y-%m-%dT%T.%N Z")"
  echo "$CH"
  echo "channel:   $CH"         >"${rec_path}/DAB_$CH.log"
  echo "last GPS:  $($HOME/bin/get_gpstime.sh)" &>>"${rec_path}/DAB_$CH.log"
  echo "curr time: ${DTF}"   &>>"${rec_path}/DAB_$CH.log"
  echo "" &>>"${rec_path}/DAB_$CH.log"
  if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
    echo -e "$(date -u "+%Y-%m-%dT%T Z"): Temperature at scanDAB.sh before dab-rtlsdr -C ${CH}: $(cat /sys/class/thermal/thermal_zone0/temp)" >>$HOME/ram/scanner.log
  fi
  dab-rtlsdr -C $CH ${DABOPT} &>>"${rec_path}/DAB_$CH.log"
  NL=$( cat "${rec_path}/DAB_$CH.log" | grep -c programnameHandler )
  if [ $NL -eq 0 ]; then
    if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
      echo "${DTF}: DAB ${CH}: NO station" >>$HOME/ram/scanner.log
      mv "${rec_path}/DAB_${CH}.log" "${rec_path}/DAB_${CH}_no-station.log"
    else
      rm "${rec_path}/DAB_${CH}.log"
    fi
  else
    echo "DAB_$CH" >$HOME/ram/LAST
    if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
      echo "${DTF}: DAB ${CH}: DETECTED station" >>$HOME/ram/scanner.log
    fi
    if [ ${FMLIST_SCAN_FOUND_PWMTONE} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
      pipwm 2000 10
    fi
    if [ ${FMLIST_SCAN_FOUND_LEDPLAY} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
      sudo -E $HOME/bin/rpi3b_led_next.sh
    fi
  fi
done

if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
  echo -e "$(date -u "+%Y-%m-%dT%T Z"): Temperature at scanDAB.sh after dab-rtlsdr: $(cat /sys/class/thermal/thermal_zone0/temp)" >>$HOME/ram/scanner.log
fi

TEND="$(date -u +%s)"
TDUR=$[ $TEND - $TBEG ]
DTF="$(date -u "+%Y-%m-%dT%T.%N Z")"
echo "DAB scan finished at ${DTF}"
echo "DAB scan finished at ${DTF}" >>${rec_path}/scan_duration.txt
echo "DAB scan duration ${TDUR} sec"
echo "DAB scan finished ${TDUR} sec" >>${rec_path}/scan_duration.txt
if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
  echo "DAB scan finished at ${DTF}. Duration ${TDUR} sec." >>$HOME/ram/scanner.log
fi

