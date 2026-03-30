#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

# desired audio samplerate
ASRATE=16000
# desired coarse MPX rate, which will get decimated to audio samplerate
MPXRATE=171000
# samplerate for RDS decoding == 3 * 57 kHz
RDSRATE=171000
#
RFRATE=1000000
# recording duration in secs
RECDURATION=10

if [ "$1" = "-h" ] || [ "$1" = "--h" ] || [ "$1" = "--help" ]; then
  echo "usage $0 <freq in kHz> [ tests .. ]"
  echo "  default frequency: 87600 kHz"
  echo "  tests - default: all"
  echo " 1 : rtl_test"
  echo " 2 : rtl_fm | redsea"
  echo " 3 : rtl_fm | play"
  echo " 4 : rtl_sdr to ramdisk"
  echo " 5 : csdr from ramdisk | redsea"
  echo " 6 : rtl_sdr | csdr | redsea"
  exit 0
fi

if [ ! -z "$1" ]; then
  TUNEFREQK="$1"
  shift
else
  TUNEFREQK="87600"
fi
TUNEFREQ=$[ ${TUNEFREQK} * 1000 ]
echo "using test frequency ${TUNEFREQK} kHz on UKW/FM"

if [ -z "$1" ]; then
  ARGS="1 2 3 4 5 6"
else
  ARGS=$*
fi

for testNo in $(echo $ARGS); do
  echo " "
  echo "------------------------------------------"
  echo "starting test ${testNo}"
  echo "------------------------------------------"
  echo " "

  case "$testNo" in
    "1")
      echo "test dongle:"
      echo "rtl_test"
      echo ""
      echo "-----------------------------------"
      echo "Press Ctrl+C to abort"
      echo "-----------------------------------"
      echo ""
      rtl_test
      sleep 5
      ;;

    "2")
      echo "testing dongle + rtl_fm + redsea"
      echo ""
      echo "rtl_fm -M fm -l 0 -A std -p 0 -s $RDSRATE -F 9 -f $TUNEFREQ | redsea -p --streams --bler -r $MPXRATE"
      echo ""
      echo "Whereas \$RDSRATE is $RDSRATE, \$TUNEFREQ is $TUNEFREQ and \$MPXRATE is $MPXRATE"
      echo ""
      echo "-----------------------------------"
      echo "You should see some JSON texts"
      echo "Press Ctrl+C to abort afterwards"
      echo "-----------------------------------"
      echo ""
      rtl_fm -M fm -l 0 -A std -p 0 -s $RDSRATE -F 9 -f $TUNEFREQ | redsea -p --streams --bler -r $MPXRATE
      ;;

    "3")
      echo "testing dongle + rtl_fm + play"
      echo ""
      DECIM=$[ $MPXRATE / $ASRATE ]
      RSRATE=$[ $ASRATE * $DECIM ]
      echo "rtl_fm -M wbfm -s $RSRATE -E rdc -r $ASRATE -f $TUNEFREQ | play -r $ASRATE -t raw -e s -b 16 -c 1 -V1 -"
      echo ""
      echo "whereas \$RSRATE = $RSRATE, \$ASRATE = $ASRATE, \$TUNEFREQ = $TUNEFREQ"
      echo ""
      echo "-----------------------------------------------"
      echo "You should hear audio (if sound is connected)"
      echo "Press Ctrl+C to abort afterwards"
      echo "-----------------------------------------------"
      echo ""
      echo "receiving at $RSRATE , decimating by $DECIM , playing audio at $ASRATE Hz"
      rtl_fm -M wbfm -s $RSRATE -E rdc -r $ASRATE -f $TUNEFREQ | play -r $ASRATE -t raw -e s -b 16 -c 1 -V1 -
      ;;


    "4")
      DECIM=$[ 1 + $RFRATE / $RDSRATE ]
      SRATE=$[ $RDSRATE * $DECIM ]
      RCVFRQ=$[ $SRATE / 4 ]
      LOFREQ=$[ $TUNEFREQ - $RCVFRQ ]
      NUMSMP=$[ $RECDURATION * $SRATE ]
      echo "recording 10 secs with rtl_sdr to ramdisk."
      echo ""
      echo "rtl_sdr -s $SRATE -n $NUMSMP -f $LOFREQ  ${FMLIST_SCAN_RAM_DIR}/test.raw"
      echo ""
      echo "and then"
      echo "ls -alh ${FMLIST_SCAN_RAM_DIR}/test.raw"
      echo ""
      echo "--------------------------"
      echo "Please wait for 10 secs"
      echo "and do NOT press Ctrl+C"
      echo "--------------------------"
      echo ""
      echo "recording at RF rate $SRATE , decimating by $DECIM to $RDSRATE"
      rtl_sdr -s $SRATE -n $NUMSMP -f $LOFREQ  ${FMLIST_SCAN_RAM_DIR}/test.raw
      ls -alh ${FMLIST_SCAN_RAM_DIR}/test.raw
      echo "filesize must be ~ $[ ( $SRATE * $RECDURATION * 2 ) / 1024 / 1024 ] MB .. check this now!"
      echo ""
      echo "----------------------------"
      echo "will automatically continue"
      echo "in 5 seconds"
      echo "----------------------------"
      echo ""
      sleep 5
      ;;

    "5")
      echo "testing record + csdr + redsea!"
      DECIM=$[ 1 + $RFRATE / $RDSRATE ]
      SRATE=$[ $RDSRATE * $DECIM ]
      RCVFRQ=$[ $SRATE / 4 ]
      LOFREQ=$[ $TUNEFREQ - $RCVFRQ ]
      NUMSMP=$[ $RECDURATION * $SRATE ]
      echo "(Again) recording 10 secs with rtl_sdr to ramdisk."
      echo ""
      echo "rtl_sdr -s $SRATE -n $NUMSMP -f $LOFREQ  ${FMLIST_SCAN_RAM_DIR}/test.raw"
      echo ""
      echo "then use this test.raw and process with csdr and then pipe to"
      echo ""
      echo "redsea -p --bler -r $RDSRATE"
      echo ""
      echo "--------------------------"
      echo "Please wait for 10 secs"
      echo "and do NOT press Ctrl+C"
      echo "--------------------------"
      echo ""
      echo "recording at RF rate $SRATE , decimating by $DECIM to $RDSRATE"
      rtl_sdr -s $SRATE -n $NUMSMP -f $LOFREQ  ${FMLIST_SCAN_RAM_DIR}/test.raw
      cat ${FMLIST_SCAN_RAM_DIR}/test.raw \
       | csdr convert -i char -o float \
       | csdr dcblock \
       | csdr shift -0.25 2>/dev/null \
       | csdr firdecimate --window=hamming $DECIM 0.125 2>/dev/null \
       | csdr fmdemod \
       | csdr convert -i float -o s16 \
       | redsea -p --bler -r $RDSRATE
      ;;

    "6")
      DECIM=8
      SRATE=$[ $RDSRATE * $DECIM ]
      RCVFRQ=$[ $SRATE / 4 ]
      LOFREQ=$[ $TUNEFREQ - $RCVFRQ ]
      echo "receiving, demodulating and decoding RDS .."
      echo "receiving at RF rate $SRATE, decimating by $DECIM to $RDSRATE"
      echo "=> relative receive frequency is 1/4 of samplerate = $RCVFRQ"
      echo "=> \$LOFREQ = $LOFREQ, \$MPXRATE = $MPXRATE"
      echo ""
      echo "-----------------------"
      echo "Press Ctrl+C to abort"
      echo "-----------------------"
      echo ""
      rtl_sdr -s $SRATE -f $LOFREQ - \
      | csdr convert -i char -o float \
      | csdr dcblock \
      | csdr shift -0.25 2>/dev/null \
      | csdr firdecimate 8 0.125 --window=hamming 2>/dev/null \
      | csdr fmdemod \
      | csdr convert -i float -o s16 \
      | redsea -p --bler -r $MPXRATE
      ;;

    *)
      echo " "
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      echo "error: unknown test $testNo"
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      echo " "
      ;;
  esac
done

