#!/bin/bash

source $HOME/.config/fmlist_scan

if [ "${FMLIST_SCAN_FM}" == "0" ] || [ "${FMLIST_SCAN_FM}" == "OFF" ]; then
  echo "FM scan is deactivated with FMLIST_SCAN_FM=${FMLIST_SCAN_FM} in $HOME/.config/fmlist_scan"
  exit 0
fi


DTF="$(date -u "+%Y-%m-%dT%T.%N Z")"
DTFREC="$(date -u "+%Y-%m-%dT%H%M%S")"
TBEG="$(date -u +%s)"

rec_path="$HOME/ram/scan_${DTFREC}_FM"
if [ ! -z "$1" ]; then
  rec_path="$HOME/ram/$1"
fi
if [ ! -d "${rec_path}" ]; then
  mkdir -p "${rec_path}"
fi

echo "FM scan started at ${DTF}"
echo "FM scan started at ${DTF}" >${rec_path}/scan_duration.txt


if [ ! -f $HOME/ram/fmscan.inc ]; then
  if [ -f $HOME/.config/fmscan.inc ]; then
    cp $HOME/.config/fmscan.inc $HOME/ram/
    echo "copied scan parameters from $HOME/.config/fmscan.inc to $HOME/ram/fmscan.inc. edit this file for use with next scan."
  else
    cat - <<EOF >$HOME/ram/fmscan.inc
chunkduration=4
par_jobs=3
ddc_step=100000
ukw_beg=87500000
ukw_end=108000000
# mpxsrate = 171 kHz; default factor = 11 => chunkbw = 1881 kHz
# mpxsrate = 171 kHz; factor = 9 => chunkbw = 1539 kHz
# mpxsrate = 171 kHz; factor = 8 => chunkbw = 1368 kHz
# mpxsrate = 171 kHz; factor = 7 => chunkbw = 1197 kHz
# mpxsrate = 171 kHz; factor = 6 => chunkbw = 1026 kHz
mpxsrate_chunkbw_factor=11
# R820T tuner bandwidths in kHz: 350, 450, 550, 700, 900, 1200, 1450, 1550, 1600, 1700, 1800, 1900, 1950, 2050, 2080
RTL_BW_OPT="-w 1550000"
EOF
    echo "wrote default scan parameters to $HOME/ram/fmscan.inc. edit this file for use with next scan."
  fi
fi
echo "reading scan parameters (chunkduration, par_jobs, ddc_step, ukw_beg, ukw_end) from $HOME/ram/fmscan.inc"
source $HOME/ram/fmscan.inc

DISPLAY=""
pilotfreq=19000
# rdsfreq = 19 * 3 = 57 kHz
rdsfreq=$[ $pilotfreq * 3 ]
# mpxsrate = 57 * 3 = 171 kHz
mpxsrate=$[ $rdsfreq * 3 ]

# chunksrate = 171 * 14 = 2394 kHz
chunk2mpx_dec=14
chunksrate=$[ $mpxsrate * $chunk2mpx_dec ]
chunkbw=$[ $mpxsrate * $mpxsrate_chunkbw_factor ]
chunknumsmp=$[ $chunkduration * $chunksrate ]
chunkrectimeout=$[ $chunkduration + 2 ]
chunkreckilltime=$[ $chunkduration + 5 ]
chunk2mpx_nfc=$( echo "1.0 / $chunk2mpx_dec" | octave -q --no-gui | sed 's/ans = //g' )

ddc_hstep=$[ ${ddc_step} / 2 ]
ddc_beg=$[ -$chunkbw / 2 + $ddc_step / 2 ]
ddc_end=$[ $chunkbw / 2 - $ddc_step / 2 ]
ddc_pfreqs="$(seq $ddc_hstep $ddc_step $ddc_end)"
ddc_nfreqs="$(seq -$ddc_hstep -$ddc_step -$ddc_end)"
ddc_freqs=$( ( seq $ddc_hstep $ddc_step $ddc_end ; seq -$ddc_hstep -$ddc_step -$ddc_end ) | sort -n )
ddc_fmin=$( echo "$ddc_freqs" | head -n 1 )
ddc_fmax=$( echo "$ddc_freqs" | tail -n 1 )
ddc_span=$[ $ddc_fmax + $ddc_fmax + $ddc_step ]
ddc_freqs=$( ( seq $ddc_hstep $ddc_step $ddc_end ; seq -$ddc_hstep -$ddc_step -$ddc_end ) | sort -n | sed -z 's/\n/ /g' )

cachedNrfFile="$HOME/ram/ddc_freqs_bw${chunkbw}_step${ddc_step}_fs${chunksrate}.inc"
localNrfFile="${FMLIST_SCAN_PATH}/ddc_freqs_bw${chunkbw}_step${ddc_step}_fs${chunksrate}.inc"
if [ ! -f "${cachedNrfFile}" ]; then
  if [ -f "${localNrfFile}" ]; then
    # copy, then source / include from cache
    cp "${localNrfFile}" "${cachedNrfFile}"
    source "${cachedNrfFile}"
  else
    # calculate normalized frequencies and prepare cache file
    ddci=0
    for ddcf in `echo $ddc_freqs` ; do
      ddcnrfreq[$ddci]=$( echo "-1 * $ddcf / $chunksrate" |octave -q --no-gui | sed 's/ans = //g' )
      # cache normalized relative frequency
      echo "ddcnrfreq[$ddci]=\"${ddcnrfreq[$ddci]}\"" >>"${cachedNrfFile}"
      ddci=$[ $ddci + 1 ]
    done
    cp "${cachedNrfFile}" "${localNrfFile}"
  fi
else
  # source / include from cache
  source "${cachedNrfFile}"
fi

chunks_beg_f=$[ $ukw_beg + $ddc_fmax ]
chunks_end_f=$[ $ukw_end + $ddc_fmax ]
chunkfrqs=$( seq $chunks_beg_f $ddc_span $chunks_end_f )

echo "mpx srate is $mpxsrate"
echo "recording is in chunks of $chunkduration secs at $chunksrate"
echo "ddc freqs are $ddc_freqs"
echo "ddc min freq is $ddc_fmin"
echo "ddc max freq is $ddc_fmax"
echo "ddc_span is $ddc_span"
echo "chunkfrqs are $chunkfrqs"

echo "mpx srate is $mpxsrate"    >>${rec_path}/scan_duration.txt
echo "recording is in chunks of $chunkduration secs at $chunksrate" >>${rec_path}/scan_duration.txt
echo "ddc freqs are $ddc_freqs"  >>${rec_path}/scan_duration.txt
echo "ddc min freq is $ddc_fmin" >>${rec_path}/scan_duration.txt
echo "ddc max freq is $ddc_fmax" >>${rec_path}/scan_duration.txt
echo "ddc_span is $ddc_span"     >>${rec_path}/scan_duration.txt
echo "chunkfrqs are $chunkfrqs"  >>${rec_path}/scan_duration.txt


act_rec_name=A
rdy_rec_name=B
rec_freq=0

GPS_ACT=""
GPS_RDY=""
DTF_ACT=""
DTF_RDY=""

rm ${rec_path}/${act_rec_name}.raw
rm ${rec_path}/${rdy_rec_name}.raw

echo starting loop over chunkfrqs

for chunkfreq in `echo $chunkfrqs EOL` ; do

  if [ -f "$HOME/ram/stopScanLoop" ]; then
    break
  fi

  if [ ! "$chunkfreq" == "EOL" ]; then
    GPS_ACT="$($HOME/bin/get_gpstime.sh)"
    DTF_ACT="$(date -u "+%Y-%m-%dT%T.%N Z")"
    echo "recording frequency $chunkfreq in background. last gps ${GPS_ACT}. now ${DTF_ACT}: rtl_sdr -s $chunksrate -n $chunknumsmp -f $chunkfreq ${rec_path}/${act_rec_name}.raw"
    if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
      echo -e "\\n$(date -u "+%Y-%m-%dT%T Z"): Temperature at scanFM.sh before rtl_sdr -f ${chunkfreq}: $(cat /sys/class/thermal/thermal_zone0/temp)" >>$HOME/ram/scanner.log
    fi
    timeout -s SIGKILL -k ${chunkreckilltime} ${chunkrectimeout} rtl_sdr -s $chunksrate -n $chunknumsmp -f $chunkfreq ${RTLSDR_OPT} ${RTL_BW_OPT} ${rec_path}/${act_rec_name}.raw &>${rec_path}/${act_rec_name}.log &
    recpid=$!
  fi

  if [ -f ${rec_path}/${rdy_rec_name}.raw ]; then
    # prepare processing with parallel
    if [ -f ${rec_path}/rec${rec_freq}.sh ]; then
      rm ${rec_path}/rec${rec_freq}.sh
    fi
    if [ -f ${rec_path}/rec${rec_freq}.txt ]; then
      rm ${rec_path}/rec${rec_freq}.txt
    fi

    cat - >${rec_path}/rec${rec_freq}.sh <<EOF
#!bash
cd ${rec_path}
ddc_freqs=( ${ddc_freqs[@]} )
ddcnrfreq=( ${ddcnrfreq[@]} )
f=\$[ $rec_freq + \${ddc_freqs[\$1]} ]
#echo -e "\\n***\\n*** freq $rec_freq + \${ddc_freqs[\$1]} = \$f\\n***"
echo "f = rec_freq $rec_freq + ddc_freqs[\$1] \${ddc_freqs[\$1]} = \${f}" >redsea.\${f}.txt
echo "normalized f = \${ddcnrfreq[\$1]}" >>redsea.\${f}.txt
echo "last GPS:  ${GPS_RDY}" >>redsea.\${f}.txt
echo "curr time: ${DTF_RDY}" >>redsea.\${f}.txt
echo "" >>redsea.\${f}.txt

cat ${rdy_rec_name}.raw \
 | csdr convert_u8_f \
 | csdr fastdcblock_ff \
 | csdr shift_addfast_cc \${ddcnrfreq[\$1]} 2>/dev/null \
 | csdr fir_decimate_cc $chunk2mpx_dec $chunk2mpx_nfc HAMMING 2>/dev/null \
 | csdr fmdemod_quadri_cf \
 | csdr convert_f_s16 \
 | redsea --bler \
 >> redsea.\${f}.txt

NL=\$(cat redsea.\${f}.txt | wc -l)

if [ \$NL -le 5 ]; then
  echo "processing freq \$f : no decode"
  if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
    echo "${DTF_RDY}: FM \${f}: NO RDS decode" >>$HOME/ram/scanner.log
    mv redsea.\${f}.txt redsea.\${f}_noRDS.txt
  else
    rm redsea.\${f}.txt
  fi
else
  echo "processing freq \$f : decoded rds"
  echo "FM \$f" >$HOME/ram/LAST
  if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
    echo "${DTF_RDY}: FM \$f: decoded RDS" >>$HOME/ram/scanner.log
  fi
  if [ ${FMLIST_SCAN_FOUND_PWMTONE} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
    pipwm 2000 10
  fi
  if [ ${FMLIST_SCAN_FOUND_LEDPLAY} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
    sudo -E $HOME/bin/rpi3b_led_next.sh
  fi
fi
EOF
    chmod a+x ${rec_path}/rec${rec_freq}.sh

    echo "checkSpectrumForCarrier details" >>$HOME/ram/scanner.log
    if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
      CPWRFN="${rec_path}/det${rec_freq}.csv"
    else
      CPWRFN=""
    fi
    checkSpectrumForCarrier ${rec_path}/${rdy_rec_name}.raw ${chunksrate} 200 150000 100000 ${FMLIST_SCAN_FM_MIN_PWR_RATIO} "${CPWRFN}" - ${ddc_freqs} 2>>$HOME/ram/scanner.log >$HOME/ram/checkSpecResults
    echo "checkSpectrumForCarrier results" >>$HOME/ram/scanner.log
    cat $HOME/ram/checkSpecResults >>$HOME/ram/scanner.log
    if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
      cp $HOME/ram/checkSpecResults ${rec_path}/det${rec_freq}.txt
    fi

    source $HOME/ram/checkSpecResults
    ddci=0
    for ddcf in `echo $ddc_freqs` ; do
      rfreq=$[ $rec_freq + $ddcf ]
      if [ $rfreq -le $ukw_end ]; then
        #echo add to parallel list: rfreq $rfreq - normalized ${ddcnrfreq[$ddci]}
        if [ ${carrier_det[$ddci]} -gt 0 ]; then
          echo "$ddci" >>${rec_path}/rec${rec_freq}.txt
          if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
            cat - <<EOF >>${rec_path}/det${rec_freq}.txt

found carrier at relative carrier_frq ${carrier_frq[$ddci]} is at absolute $[ ${rec_freq} + ${carrier_frq[$ddci]} ] Hz
power ratio left  ${carrier_pwr_ratioL[$ddci]}
power ratio right ${carrier_pwr_ratioR[$ddci]}
EOF
          fi
        fi
      fi
      ddci=$[ $ddci + 1 ]
    done

    if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
      echo -e "$(date -u "+%Y-%m-%dT%T Z"): Temperature at scanFM.sh before parallel: $(cat /sys/class/thermal/thermal_zone0/temp)" >>$HOME/ram/scanner.log
    fi
    # batch process prepared scripts in/with parallel
    # use nice, that processing does not disturb background recording of next chunk
    time nice parallel --no-notice --jobs ${par_jobs} "bash ${rec_path}/rec${rec_freq}.sh" <${rec_path}/rec${rec_freq}.txt
    if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
      echo -e "$(date -u "+%Y-%m-%dT%T Z"): Temperature at scanFM.sh after parallel of ${carrier_num_det} carriers: $(cat /sys/class/thermal/thermal_zone0/temp)" >>$HOME/ram/scanner.log
    fi

    # delete processed file
    # rm ${rec_path}/${rdy_rec_name}.raw

    # deleted processed temporary script and frequency list
    rm ${rec_path}/rec${rec_freq}.sh  ${rec_path}/rec${rec_freq}.txt

    if [ ${FMLIST_SCAN_SAVE_RAW} -gt 0 ]; then
      if [ ${rec_freq} -ge ${FMLIST_SCAN_SAVE_MINFREQ} ] && [ ${rec_freq} -le ${FMLIST_SCAN_SAVE_MAXFREQ} ]; then
        # see https://unix.stackexchange.com/questions/87908/how-do-you-empty-the-buffers-and-cache-on-a-linux-system
        sudo sh -c 'echo 3 >/proc/sys/vm/drop_caches'
        MFREE=$( free -m | grep "^Mem:" | awk '{ print $4; }' )
        if [ ${MFREE} -ge ${FMLIST_SCAN_SAVE_MIN_MEM} ]; then
          mv ${rec_path}/${rdy_rec_name}.raw ${rec_path}/raw__srate_${chunksrate}__freq_${rec_freq}.bin
          gzip ${rec_path}/raw__srate_${chunksrate}__freq_${rec_freq}.bin
          echo "$(date -u "+%Y-%m-%dT%T Z"): keeping record as raw__srate_${chunksrate}__freq_${rec_freq}.bin" >>$HOME/ram/scanner.log
        else
          echo "$(date -u "+%Y-%m-%dT%T Z"): ${MFREE} MB free memory is below ${FMLIST_SCAN_SAVE_MIN_MEM}: NOT keeping record of freq ${rec_freq}" >>$HOME/ram/scanner.log
        fi
      fi
    fi
  fi

  # switch files
  if [ "${act_rec_name}" == "A" ]; then
    act_rec_name=B
    rdy_rec_name=A
  else
    act_rec_name=A
    rdy_rec_name=B
  fi
  # switch GPS/TIME
  GPS_RDY="${GPS_ACT}"
  DTF_RDY="${DTF_ACT}"

  rec_freq=$chunkfreq

  if [ ! "$chunkfreq" == "EOL" ]; then
    echo "waiting for record with pid ${recpid} to finish .."
    wait $recpid
    sleep 0.5

    if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
      echo "rtl_sdr -s $chunksrate -n $chunknumsmp -f $chunkfreq ${rec_path}/${rdy_rec_name}.raw finished" >>$HOME/ram/scanner.log
      echo "ls -alh ${rec_path}/*.raw :" >>$HOME/ram/scanner.log
      ls -alh ${rec_path}/*.raw >>$HOME/ram/scanner.log
      cat ${rec_path}/${act_rec_name}.log >>$HOME/ram/scanner.log
    fi
  fi

done

if /bin/true; then
  # delete recording itself
  rm ${rec_path}/${act_rec_name}.raw
  rm ${rec_path}/${rdy_rec_name}.raw
fi

TEND="$(date -u +%s)"
TDUR=$[ $TEND - $TBEG ]
DTF="$(date -u "+%Y-%m-%dT%T.%N Z")"
echo "FM scan finished at ${DTF}"
echo "FM scan finished at ${DTF}" >>${rec_path}/scan_duration.txt
echo "FM scan duration ${TDUR} sec"
echo "FM scan finished ${TDUR} sec" >>${rec_path}/scan_duration.txt
if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
  echo "FM scan finished at ${DTF}. Duration ${TDUR} sec." >>$HOME/ram/scanner.log
fi

