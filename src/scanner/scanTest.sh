#!/bin/bash

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
  ARGS="1 2 3 4 5"
else
  ARGS=$*
fi

for testNo in $(echo $ARGS); do
  echo "starting test ${testNo}"

  case "$testNo" in
    "1")
      echo "test dongle:"
      echo "rtl_test"
      echo "Press Ctrl+C to abort"
      rtl_test
      sleep 5
      ;;

    "2")
      echo "testing dongle + rtl_fm + redsea .. you should see some JSON text:"
      echo "rtl_fm -M fm -l 0 -A std -p 0 -s $RDSRATE -F 9 -f $TUNEFREQ | redsea --bler"
      echo "Press Ctrl+C to abort"
      rtl_fm -M fm -l 0 -A std -p 0 -s $RDSRATE -F 9 -f $TUNEFREQ | redsea --bler
      ;;

    "3")
      echo "testing dongle + rtl_fm + play .. you should head audio - when sound connected?!"
      echo "Press Ctrl+C to abort"
      DECIM=$[ $MPXRATE / $ASRATE ]
      RSRATE=$[ $ASRATE * $DECIM ]
      echo "receiving at $RSRATE , decimating by $DECIM , playing audio at $ASRATE Hz"
      rtl_fm -M wbfm -s $RSRATE -E rdc -r $ASRATE -f $TUNEFREQ | play -r $ASRATE -t raw -e s -b 16 -c 1 -V1 -
      ;;


    "4")
      DECIM=$[ 1 + $RFRATE / $RDSRATE ]
      SRATE=$[ $RDSRATE * $DECIM ]
      RCVFRQ=$[ $SRATE / 4 ]
      LOFREQ=$[ $TUNEFREQ - $RCVFRQ ]
      NUMSMP=$[ $RECDURATION * $SRATE ]
      echo "recording 10 secs with rtl_sdr to ramdisk. Please wait!"
      echo "recording at RF rate $SRATE , decimating by $DECIM to $RDSRATE"
      rtl_sdr -s $SRATE -n $NUMSMP -f $LOFREQ  $HOME/ram/test.raw
      ls -alh $HOME/ram/test.raw
      echo "filesize must be ~ $[ ( $SRATE * $RECDURATION * 2 ) / 1024 / 1024 ] MB .. check this now!"
      sleep 5
      ;;

    "5")
      echo "testing record + csdr + redsea!"
      cat $HOME/ram/test.raw \
       | csdr convert_u8_f \
       | csdr fastdcblock_ff \
       | csdr shift_addfast_cc -0.25 2>/dev/null \
       | csdr fir_decimate_cc 8 0.125 HAMMING 2>/dev/null \
       | csdr fmdemod_quadri_cf \
       | csdr convert_f_s16 \
       | redsea --bler
      ;;

    "6")
      DECIM=8
      SRATE=$[ $RDSRATE * $DECIM ]
      RCVFRQ=$[ $SRATE / 4 ]
      LOFREQ=$[ $TUNEFREQ - $RCVFRQ ]
      echo "receiving, demodulating and decoding RDS .."
      echo "receiving at RF rate $SRATE, decimating by $DECIM to $RDSRATE"
      echo "=> relative receive frequency is 1/4 of samplerate = $RCVFRQ"
      echo "=> LO frequency = $LOFREQ"
      echo "Press Ctrl+C to abort"
      rtl_sdr -s $SRATE -f $LOFREQ - \
       | csdr convert_u8_f \
       | csdr fastdcblock_ff \
       | csdr shift_addfast_cc -0.25 \
       | csdr fir_decimate_cc 8 0.125 HAMMING \
       | csdr fmdemod_quadri_cf \
       | csdr convert_f_s16 \
       | redsea --bler
      ;;

    *)
      echo "error: unknown test $testNo"
      ;;
  esac
done

