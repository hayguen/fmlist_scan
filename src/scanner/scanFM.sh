#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

if [ "${FMLIST_SCAN_FM}" == "0" ] || [ "${FMLIST_SCAN_FM}" == "OFF" ]; then
  echo "FM scan is deactivated with FMLIST_SCAN_FM=${FMLIST_SCAN_FM} in $HOME/.config/fmlist_scan/config"
  exit 0
fi


DTF="$(date -u "+%Y-%m-%dT%T.%N Z")"
DTFREC="$(date -u "+%Y-%m-%dT%H%M%S")"
TBEG="$(date -u +%s)"

rec_path="${FMLIST_SCAN_RAM_DIR}/scan_${DTFREC}_FM"
if [ ! -z "$1" ]; then
  rec_path="${FMLIST_SCAN_RAM_DIR}/$1"
fi
if [ ! -d "${rec_path}" ]; then
  mkdir -p "${rec_path}"
fi

echo "FM scan started at ${DTF}"
echo "FM scan started at ${DTF}" >${rec_path}/scan_duration.txt

# get ${GPSSRC} for use in fmscan.inc
GPSVALS=$( ( flock -s 213 ; cat ${FMLIST_SCAN_RAM_DIR}/gpscoor.inc 2>/dev/null ) 213>${FMLIST_SCAN_RAM_DIR}/gps.lock )
echo "${GPSVALS}" >${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
source ${FMLIST_SCAN_RAM_DIR}/gpsvals.inc
rm ${FMLIST_SCAN_RAM_DIR}/gpsvals.inc

if [ ! -f ${FMLIST_SCAN_RAM_DIR}/fmscan.inc ]; then
  if [ -f $HOME/.config/fmlist_scan/fmscan.inc ]; then
    cp $HOME/.config/fmlist_scan/fmscan.inc ${FMLIST_SCAN_RAM_DIR}/
    echo "copied scan parameters from $HOME/.config/fmlist_scan/fmscan.inc to ${FMLIST_SCAN_RAM_DIR}/fmscan.inc. edit this file for use with next scan."
  else
    cat - <<EOF >${FMLIST_SCAN_RAM_DIR}/fmscan.inc
chunkduration=4
selchunkduration=4
selchunkfreqs=()
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
    echo "wrote default scan parameters to ${FMLIST_SCAN_RAM_DIR}/fmscan.inc. edit this file for use with next scan."
  fi
fi


if [ -f "${FMLIST_SCAN_RAM_DIR}/fmscan.no" ]; then
  export FMSCAN_NO=$( cat "${FMLIST_SCAN_RAM_DIR}/fmscan.no" )
else
  export FMSCAN_NO="0"
fi
export FMSCAN_NO=$[ ${FMSCAN_NO} + 1 ]

echo "reading scan parameters (chunkduration, par_jobs, ddc_step, ukw_beg, ukw_end) from ${FMLIST_SCAN_RAM_DIR}/fmscan.inc"
source ${FMLIST_SCAN_RAM_DIR}/fmscan.inc

echo -n "${FMSCAN_NO}" >${FMLIST_SCAN_RAM_DIR}/fmscan.no


DISPLAY=""
pilotfreq=19000
# rdsfreq = 19 * 3 = 57 kHz
rdsfreq=$[ $pilotfreq * 3 ]
# mpxsrate = 57 * 3 = 171 kHz
mpxsrate=$[ $rdsfreq * 3 ]

# chunksrate = 171 * 14 = 2394 kHz
if [ -z "${chunk2mpx_dec}" ]; then
  chunk2mpx_dec=14
fi
chunksrate=$[ $mpxsrate * $chunk2mpx_dec ]
chunkbw=$[ $mpxsrate * $mpxsrate_chunkbw_factor ]
chunknumsmp=$[ $chunkduration * $chunksrate ]
chunkrectimeout=$[ $chunkduration + 2 ]
chunkreckilltime=$[ $chunkduration + 5 ]
selchunknumsmp=$[ $selchunkduration * $chunksrate ]
selchunkrectimeout=$[ $selchunkduration + 2 ]
selchunkreckilltime=$[ $selchunkduration + 5 ]
chunk2mpx_nfc=$( echo "1.0 / $chunk2mpx_dec" | octave -q --no-gui | sed 's/ans = //g' )

ddc_hstep=$[ ${ddc_step} / 2 ]
if [ -z "${center_beg}" ] || [ -z "${center_last}" ]; then
  ddc_beg=$[ -$chunkbw / 2 + $ddc_step / 2 ]
  ddc_end=$[ $chunkbw / 2 - $ddc_step / 2 ]
  ddc_pfreqs="$(seq $ddc_hstep $ddc_step $ddc_end)"
  ddc_nfreqs="$(seq -$ddc_hstep -$ddc_step -$ddc_end)"
  ddc_freqs=$( ( seq $ddc_hstep $ddc_step $ddc_end ; seq -$ddc_hstep -$ddc_step -$ddc_end ) | sort -n )
  ddc_fmin=$( echo "$ddc_freqs" | head -n 1 )
  ddc_fmax=$( echo "$ddc_freqs" | tail -n 1 )
  ddc_span=$[ $ddc_fmax + $ddc_fmax + $ddc_step ]
  ddc_freqs=$( ( seq $ddc_hstep $ddc_step $ddc_end ; seq -$ddc_hstep -$ddc_step -$ddc_end ) | sort -n | sed -z 's/\n/ /g' )
  NrfFileBase="ddc_freqs_bw${chunkbw}_step${ddc_step}_fs${chunksrate}"
else
  # workaround - 0 doesn't calculate any ddc_freqs
  if [ "${center_beg}" = "0" ]; then
    center_beg="10000"
  fi
  if [ "${center_last}" = "0" ]; then
    center_last="-10000"
  fi

  beg_sgn=$[  ${center_beg}  / ${center_beg#-}  ]
  last_sgn=$[ ${center_last} / ${center_last#-} ]
  if [ "${beg_sgn}" = "${last_sgn}" ]; then
    ddc_beg="${center_beg}"
    ddc_end=$[ ( ( ${center_last#-} / ${ddc_step} ) * ${ddc_step} ) * ${last_sgn} ]
    ddc_freqs=$( ( seq $ddc_beg $ddc_step $ddc_end ) | sort -n )
    ddc_fmin=$( echo "$ddc_freqs" | head -n 1 )
    ddc_fmax=$( echo "$ddc_freqs" | tail -n 1 )
    ddc_span=$[ $ddc_fmax - $ddc_fmin + $ddc_step ]
    ddc_freqs=$( ( seq $ddc_beg $ddc_step $ddc_end ) | sort -n | sed -z 's/\n/ /g' )
  else
    ddc_beg=$[ ( ( ( ${center_beg#-}  - ${ddc_hstep} ) / ${ddc_step} ) * ${ddc_step} + ${ddc_hstep} ) * ${beg_sgn}  ]
    ddc_end=$[ ( ( ( ${center_last#-} - ${ddc_hstep} ) / ${ddc_step} ) * ${ddc_step} + ${ddc_hstep} ) * ${last_sgn} ]
    ddc_freqs=$( ( seq $ddc_beg $ddc_step $ddc_end ) | sort -n )
    ddc_fmin=$( echo "$ddc_freqs" | head -n 1 )
    ddc_fmax=$( echo "$ddc_freqs" | tail -n 1 )
    ddc_span=$[ $ddc_fmax - $ddc_fmin + $ddc_step ]
    ddc_freqs=$( ( seq $ddc_beg $ddc_step $ddc_end ) | sort -n | sed -z 's/\n/ /g' )
  fi
  NrfFileBase="ddc_freqs_${mpxsrate_chunkbw_factor}_${ddc_fmin}_to_${ddc_fmax}_step${ddc_step}_fs${chunksrate}"
fi
Nddc_freqs="$( echo "${ddc_freqs}" | wc -w )"

cachedNrfFile="${FMLIST_SCAN_RAM_DIR}/${NrfFileBase}.inc"
localNrfFile="${FMLIST_SCAN_PATH}/${NrfFileBase}.inc"
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

chunks_beg_f=$[ $ukw_beg - $ddc_fmin ]
chunks_end_f=$[ $ukw_end + $ddc_fmax ]
chunkfrqs=$( seq ${chunks_beg_f} ${ddc_span} ${chunks_end_f} | tr '\n' ' ' )
Nchunkfrqs="$( echo "${chunkfrqs}" | wc -w )"

echo "fmscan.inc: RTLBW       = '${RTLBW}'"
echo "fmscan.inc: RTLC        = '${RTLC}'"
echo "fmscan.inc: FMSCAN_NO   = '${FMSCAN_NO}'"
echo "fmscan.inc: SCANMOD     = '${SCANMOD}'"
echo "fmscan.inc: BCMUL       = '${BCMUL}'"
echo "fmscan.inc: BCSHIFT     = '${BCSHIFT}'"
echo "fmscan.inc: center_beg  = '${center_beg}'"
echo "fmscan.inc: center_last = '${center_last}'"
echo "mpx srate is ${mpxsrate}"
echo "recording is in chunks of ${chunkduration} secs @ ${chunksrate} Hz"
echo "ddc_freqs are ${ddc_freqs}"
echo "#ddc_freqs is ${Nddc_freqs}"
echo "ddc_min freq is ${ddc_fmin}"
echo "ddc_max freq is ${ddc_fmax}"
echo "ddc_span is ${ddc_span}"
echo "chunkfrqs are ${chunkfrqs}"
echo "#chunkfrqs is ${Nchunkfrqs}"

echo "fmscan.inc: RTLBW       = '${RTLBW}'"       >>${rec_path}/scan_duration.txt
echo "fmscan.inc: RTLC        = '${RTLC}'"        >>${rec_path}/scan_duration.txt
echo "fmscan.inc: FMSCAN_NO   = '${FMSCAN_NO}'"   >>${rec_path}/scan_duration.txt
echo "fmscan.inc: SCANMOD     = '${SCANMOD}'"     >>${rec_path}/scan_duration.txt
echo "fmscan.inc: BCMUL       = '${BCMUL}'"       >>${rec_path}/scan_duration.txt
echo "fmscan.inc: BCSHIFT     = '${BCSHIFT}'"     >>${rec_path}/scan_duration.txt
echo "fmscan.inc: center_beg  = '${center_beg}'"  >>${rec_path}/scan_duration.txt
echo "fmscan.inc: center_last = '${center_last}'" >>${rec_path}/scan_duration.txt
echo "mpx srate is ${mpxsrate}"      >>${rec_path}/scan_duration.txt
echo "recording is in chunks of ${chunkduration} secs at ${chunksrate}" >>${rec_path}/scan_duration.txt
echo "ddc freqs are ${ddc_freqs}"    >>${rec_path}/scan_duration.txt
echo "#ddc_freqs is ${Nddc_freqs}"   >>${rec_path}/scan_duration.txt
echo "ddc min freq is ${ddc_fmin}"   >>${rec_path}/scan_duration.txt
echo "ddc max freq is ${ddc_fmax}"   >>${rec_path}/scan_duration.txt
echo "ddc_span is ${ddc_span}"       >>${rec_path}/scan_duration.txt
echo "chunkfrqs are ${chunkfrqs}"    >>${rec_path}/scan_duration.txt
echo "#chunkfrqs is ${Nchunkfrqs}"   >>${rec_path}/scan_duration.txt


act_rec_name=A
rdy_rec_name=B
rec_freq=0

GPS_ACT=""
GPS_RDY=""
GPSV_ACT=""
GPSV_RDY=""
DTF_ACT=""
DTF_RDY=""

rm ${rec_path}/${act_rec_name}.raw
rm ${rec_path}/${rdy_rec_name}.raw

echo starting loop over chunkfrqs

for chunkfreq in $( echo $chunkfrqs EOL ) ; do

  if [ -f "${FMLIST_SCAN_RAM_DIR}/stopScanLoop" ]; then
    break
  fi

  if [ ! "$chunkfreq" == "EOL" ]; then
    GPS_ACT="$($HOME/bin/get_gpstime.sh)"
    GPSV_ACT="$( ( flock -s 213 ; cat ${FMLIST_SCAN_RAM_DIR}/gpscoor.inc 2>/dev/null ) 213>${FMLIST_SCAN_RAM_DIR}/gps.lock )"
    DTF_ACT="$(date -u "+%Y-%m-%dT%T.%N Z")"
    echo "recording frequency $chunkfreq in background. last gps ${GPS_ACT}. now ${DTF_ACT}: rtl_sdr -s $chunksrate -n $chunknumsmp -f $chunkfreq ${RTLSDR_OPT} ${RTL_BW_OPT} ${rec_path}/${act_rec_name}.raw"
    if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
      echo -e "\\n$(date -u "+%Y-%m-%dT%T Z"): Temperature at scanFM.sh before rtl_sdr -f ${chunkfreq}: $(cat /sys/class/thermal/thermal_zone0/temp)" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      echo "$(date -u +%s), $(cat /sys/class/thermal/thermal_zone0/temp)" >>${FMLIST_SCAN_RAM_DIR}/cputemp.csv
    fi
    echo timeout -s SIGKILL -k ${chunkreckilltime} ${chunkrectimeout} rtl_sdr -s $chunksrate -n $chunknumsmp -f $chunkfreq ${RTLSDR_OPT} ${RTL_BW_OPT} ${rec_path}/${act_rec_name}.raw ..
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

    echo "checkSpectrumForCarrier details" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
      CPWRFN="${rec_path}/det${rec_freq}.csv"
    else
      CPWRFN=""
    fi
    checkSpectrumForCarrier ${rec_path}/${rdy_rec_name}.raw ${chunksrate} 200 150000 100000 ${FMLIST_SCAN_FM_MIN_PWR_RATIO} "${CPWRFN}" - ${ddc_freqs} 2>>${FMLIST_SCAN_RAM_DIR}/scanner.log >${FMLIST_SCAN_RAM_DIR}/checkSpecResults
    echo "checkSpectrumForCarrier results" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    cat ${FMLIST_SCAN_RAM_DIR}/checkSpecResults >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
      cp ${FMLIST_SCAN_RAM_DIR}/checkSpecResults ${rec_path}/det${rec_freq}.txt
    fi

    source ${FMLIST_SCAN_RAM_DIR}/checkSpecResults

    cat - >${rec_path}/rec${rec_freq}.sh <<EOF
#!bash
cd ${rec_path}
ddc_freqs=( ${ddc_freqs[@]} )
ddcnrfreq=( ${ddcnrfreq[@]} )
carrier_pwr_ratioMin=( ${carrier_pwr_ratioMin[@]} )
carrier_pwr_ratioMax=( ${carrier_pwr_ratioMax[@]} )
f=\$[ $rec_freq + \${ddc_freqs[\$1]} ]
#echo -e "\\n***\\n*** freq $rec_freq + \${ddc_freqs[\$1]} = \$f\\n***"

echo "f=\"\${f}\""              >redsea.\${f}.inc
echo "# f = rec_freq $rec_freq + ddc_freqs[\$1] \${ddc_freqs[\$1]} = \${f}" >>redsea.\${f}.inc
echo "# normalized f = \${ddcnrfreq[\$1]}" >>redsea.\${f}.inc
echo "CURRTIM=\"${DTF_RDY}\""  >>redsea.\${f}.inc
echo "# last GPS:  ${GPS_RDY}" >>redsea.\${f}.inc
echo "\${GPSV_RDY}"            >>redsea.\${f}.inc
echo "FM_MIN_PWR_RATIO=${FMLIST_SCAN_FM_MIN_PWR_RATIO}" >>redsea.\${f}.inc
echo "carrier_pwr_ratioMin=\"\${carrier_pwr_ratioMin[\$1]}\"" >>redsea.\${f}.inc
echo "carrier_pwr_ratioMax=\"\${carrier_pwr_ratioMax[\$1]}\"" >>redsea.\${f}.inc

CURREPOCH=\$(date -d "${DTF_RDY}" -u "+%s")
#date -d @\${CURREPOCH} -u "+%Y-%m-%dT%TZ"  # back to date/time from epoch - seconds since 1970

echo "\${GPSV_RDY}" >gpsv.\${f}.inc
source gpsv.\${f}.inc
rm gpsv.\${f}.inc
GPSCOLS="\${GPSLAT},\${GPSLON},\${GPSMODE},\${GPSALT},\${GPSTIM}"

cat ${rdy_rec_name}.raw \\
 | csdr convert_u8_f \\
 | csdr fastdcblock_ff \\
 | csdr shift_addfast_cc \${ddcnrfreq[\$1]} 2>/dev/null \\
 | csdr fir_decimate_cc $chunk2mpx_dec $chunk2mpx_nfc HAMMING 2>/dev/null \\
 | csdr fmdemod_quadri_cf \\
 | csdr convert_f_s16 \\
 | redsea --bler --output-hex \\
 > redsea.\${f}.spy

cat redsea.\${f}.spy \\
 | redsea --input-hex \\
 > redsea.\${f}.txt


NL=\$(cat redsea.\${f}.txt | wc -l)
echo "NUM_DECODED_JSON_LINES=\"\${NL}\"" >>redsea.\${f}.inc

if [ \$NL -le 0 ]; then
  echo "processing freq \$f : no decode"
  echo "RDS=\"0\"" >>redsea.\${f}.inc
  RDS="0"
  if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
    echo "${DTF_RDY}: FM \${f}: NO RDS decode" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    mv redsea.\${f}.txt redsea.\${f}_noRDS.txt
    mv redsea.\${f}.spy redsea.\${f}_noRDS.spy

    echo -n "\${CURREPOCH},freq,\${f},\${RDS}" >fm_carrier.\${f}.csv
    echo -n ",\${carrier_pwr_ratioMin[\$1]},\${carrier_pwr_ratioMax[\$1]}" >>fm_carrier.\${f}.csv
    echo ",${DTF_RDY},\${GPSCOLS}" >>fm_carrier.\${f}.csv

  else
    rm redsea.\${f}.txt
    rm redsea.\${f}.inc
  fi
else
  echo "processing freq \$f : decoded rds"
  echo "FM \$f" >${FMLIST_SCAN_RAM_DIR}/LAST
  echo "RDS=\"1\"" >>redsea.\${f}.inc
  RDS="1"
  RDSCOLS="\$( redsea.json2csv.sh redsea.\${f}.txt )"

    echo -n "\${CURREPOCH},freq,\${f},\${RDS}" >fm_rds.\${f}.csv
    echo -n ",\${carrier_pwr_ratioMin[\$1]},\${carrier_pwr_ratioMax[\$1]}" >>fm_rds.\${f}.csv
    echo -n ",${DTF_RDY},\${GPSCOLS}" >>fm_rds.\${f}.csv
    echo ",\${RDSCOLS}" >>fm_rds.\${f}.csv

  if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
    echo "${DTF_RDY}: FM \$f: decoded RDS" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  fi
  if [ ${FMLIST_SCAN_FOUND_PWMTONE} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
    scanToneFeedback.sh found
  fi
  if [ ${FMLIST_SCAN_FOUND_LEDPLAY} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
    sudo -E $HOME/bin/rpi3b_led_next.sh
  fi
fi
EOF
    chmod a+x ${rec_path}/rec${rec_freq}.sh

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
power ratio minimum ${carrier_pwr_ratioMin[$ddci]}
power ratio maximum ${carrier_pwr_ratioMax[$ddci]}
EOF
          fi
        fi
      fi
      ddci=$[ $ddci + 1 ]
    done

    if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
      echo -e "$(date -u "+%Y-%m-%dT%T Z"): Temperature at scanFM.sh before parallel: $(cat /sys/class/thermal/thermal_zone0/temp)" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      echo "$(date -u +%s), $(cat /sys/class/thermal/thermal_zone0/temp)" >>${FMLIST_SCAN_RAM_DIR}/cputemp.csv
    fi
    # batch process prepared scripts in/with parallel
    # use nice, that processing does not disturb background recording of next chunk
    time nice parallel --no-notice --jobs ${par_jobs} "bash ${rec_path}/rec${rec_freq}.sh" <${rec_path}/rec${rec_freq}.txt
    if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
      echo -e "$(date -u "+%Y-%m-%dT%T Z"): Temperature at scanFM.sh after parallel of ${carrier_num_det} carriers: $(cat /sys/class/thermal/thermal_zone0/temp)" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      echo "$(date -u +%s), $(cat /sys/class/thermal/thermal_zone0/temp)" >>${FMLIST_SCAN_RAM_DIR}/cputemp.csv
    fi

    # delete processed file
    # rm ${rec_path}/${rdy_rec_name}.raw

    # deleted processed temporary script and frequency list
    rm ${rec_path}/rec${rec_freq}.sh
    rm ${rec_path}/rec${rec_freq}.txt

    if [ ${FMLIST_SCAN_SAVE_RAW} -gt 0 ]; then
      if [ ${rec_freq} -ge ${FMLIST_SCAN_SAVE_MINFREQ} ] && [ ${rec_freq} -le ${FMLIST_SCAN_SAVE_MAXFREQ} ]; then
        # see https://unix.stackexchange.com/questions/87908/how-do-you-empty-the-buffers-and-cache-on-a-linux-system
        sudo sh -c 'echo 3 >/proc/sys/vm/drop_caches'
        MFREE=$( free -m | grep "^Mem:" | awk '{ print $4; }' )
        if [ ${MFREE} -ge ${FMLIST_SCAN_SAVE_MIN_MEM} ]; then
          mv ${rec_path}/${rdy_rec_name}.raw ${rec_path}/raw__srate_${chunksrate}__freq_${rec_freq}.bin
          gzip ${rec_path}/raw__srate_${chunksrate}__freq_${rec_freq}.bin
          echo "$(date -u "+%Y-%m-%dT%T Z"): keeping record as raw__srate_${chunksrate}__freq_${rec_freq}.bin" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
        else
          echo "$(date -u "+%Y-%m-%dT%T Z"): ${MFREE} MB free memory is below ${FMLIST_SCAN_SAVE_MIN_MEM}: NOT keeping record of freq ${rec_freq}" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
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
  export GPSV_RDY="${GPSV_ACT}"
  DTF_RDY="${DTF_ACT}"

  rec_freq=$chunkfreq

  if [ ! "$chunkfreq" == "EOL" ]; then
    echo "waiting for record with pid ${recpid} to finish .."
    wait $recpid
    sleep 0.5

    if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
      echo "rtl_sdr -s $chunksrate -n $chunknumsmp -f $chunkfreq ${rec_path}/${rdy_rec_name}.raw finished" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      echo "ls -alh ${rec_path}/*.raw :" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      ls -alh ${rec_path}/*.raw >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      cat ${rec_path}/${act_rec_name}.log >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    fi
  fi

done

if /bin/true; then
  # delete recording itself
  rm ${rec_path}/${act_rec_name}.raw
  rm ${rec_path}/${rdy_rec_name}.raw
fi

NUMRDS=$(ls -1 ${rec_path}/redsea.*.txt | grep -v _noRDS | wc -l)
NUMCAR=$(ls -1 ${rec_path}/redsea.*.txt | grep _noRDS | wc -l)
TEND="$(date -u +%s)"
TDUR=$[ $TEND - $TBEG ]
DTF="$(date -u "+%Y-%m-%dT%T.%N Z")"
echo "FM scan finished at ${DTF}"
echo "FM scan finished at ${DTF}" >>${rec_path}/scan_duration.txt
echo "FM scan duration ${TDUR} sec"
echo "FM scan duration ${TDUR} sec" >>${rec_path}/scan_duration.txt
echo "FM scan found ${NUMRDS} RDS carriers and ${NUMCAR} plain carriers"
echo "FM scan found ${NUMRDS} RDS carriers and ${NUMCAR} plain carriers" >>${rec_path}/scan_duration.txt
if [ ${FMLIST_SCAN_DEBUG} -ne 0 ]; then
  echo "FM scan finished at ${DTF}. Duration ${TDUR} sec." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
fi
if [ ${FMLIST_SCAN_RASPI} -ne 0 ] && [ ${FMLIST_SCAN_PWM_FEEDBACK} -ne 0 ]; then
  scanToneFeedback.sh fm ${NUMRDS}
fi

