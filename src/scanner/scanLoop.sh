#!/bin/bash

export LC_ALL=C
source $HOME/.config/fmlist_scan/config

if [ -f $HOME/.config/fmlist_scan/fmscan.inc ]; then
  cp $HOME/.config/fmlist_scan/fmscan.inc $HOME/ram/
fi

if [ -f $HOME/.config/fmlist_scan/dabscan.inc ]; then
  cp $HOME/.config/fmlist_scan/dabscan.inc $HOME/ram/
fi

if [ -f $HOME/.config/fmlist_scan/dab_chanlist.txt ]; then
  cp $HOME/.config/fmlist_scan/dab_chanlist.txt $HOME/ram/
fi

N=1
NUM_RTL_FAILS=0

cd $HOME/ram

if [ $( echo "$PATH" | grep -c "/usr/local/bin" ) -eq 0 ]; then
  export PATH=/usr/local/bin:$PATH
fi

if [ $( echo "$PATH" | grep -c "$HOME/bin" ) -eq 0 ]; then
  export PATH="$HOME/bin:$PATH"
fi

if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
  sudo -E $HOME/bin/rpi3b_led_init.sh
fi

if [ -f "$HOME/ram/stopScanLoop" ]; then
  rm "$HOME/ram/stopScanLoop"
fi

#

echo -e "\\nSTARTING_SCANNER\\n\\n" >>$HOME/ram/scanner.log


echo -e "\\nhostnamectl" >>$HOME/ram/scanner.log
hostnamectl >>$HOME/ram/scanner.log
echo "" >>$HOME/ram/scanner.log


echo -e "\\n/etc/os-release:" >>$HOME/ram/scanner.log
cat /etc/os-release >>$HOME/ram/scanner.log
echo "" >>$HOME/ram/scanner.log

echo -e "\\nlsb_release -a:" >>$HOME/ram/scanner.log
lsb_release -a >>$HOME/ram/scanner.log
echo "" >>$HOME/ram/scanner.log

echo -e "\\nvcgencmd version:" >>$HOME/ram/scanner.log
vcgencmd version >>$HOME/ram/scanner.log
echo "" >>$HOME/ram/scanner.log

echo -e "\\n/proc/cpuinfo:" >>$HOME/ram/scanner.log
cat /proc/cpuinfo >>$HOME/ram/scanner.log
echo "" >>$HOME/ram/scanner.log

NUMCPUS=$(cat /proc/cpuinfo | grep ^processor | wc -l)
echo -e "\\nNUMCPUS=${NUMCPUS}\\n" >>$HOME/ram/scanner.log

# temperature - human readable: $(vcgencmd measure_temp)
# temperature in /1000 degree:  $(cat /sys/class/thermal/thermal_zone0/temp)
# echo -e "\\nTemperature: $(cat /sys/class/thermal/thermal_zone0/temp)\\n" >>$HOME/ram/scanner.log

while /bin/true; do

  if [ -f "$HOME/ram/stopScanLoop" ]; then
    break
  fi

  echo $N

  # test RTL dongle
  rtl_sdr -f 100M -n 512 $HOME/ram/test.raw
  if [ $? -ne 0 ]; then
    if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
      sudo -E $HOME/bin/rpi3b_led_blinkRed.sh
      pipwm 2000 500 0 1
    fi
    NUM_RTL_FAILS=$[ ${NUM_RTL_FAILS} + 1 ]
    if [ ${NUM_RTL_FAILS} -eq ${FMLIST_SCAN_DEAD_RTL_TRIES} ] && [ ${FMLIST_SCAN_DEAD_REBOOT} -ne 0 ]; then
      sudo reboot now
    fi
    continue
  fi
  NUM_RTL_FAILS=0

  scanFM.sh
  if [ -f "$HOME/ram/stopScanLoop" ]; then
    break
  fi

  scanDAB.sh
  if [ -f "$HOME/ram/stopScanLoop" ]; then
    break
  fi

  # always save log .. to have it saved - especially when mobile
  echo -e "\\n*********** saveScanResults.sh ${FMLIST_SCAN_SAVE_LOG_OPT} \\n" >>$HOME/ram/scanner.log
  saveScanResults.sh ${FMLIST_SCAN_SAVE_LOG_OPT}

  if [ ${FMLIST_SCAN_SAVE_PWMTONE} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
    if [ ${FMLIST_SCAN_PWM_FEEDBACK} -ne 0 ]; then
      sleep 0.5
    fi
    pipwm 2000 10 0 1   50 100 50 100 50 100   150 100 150 100 150 100
  fi
  if [ ${FMLIST_SCAN_SAVE_LEDPLAY} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
    sudo -E $HOME/bin/rpi3b_led_blinkRed.sh
  fi

  N=$[ $N + 1 ]
done

echo -e "\\nend of scanLoop. calling saveScanResults.sh savelog .." >>$HOME/ram/scanner.log
saveScanResults.sh savelog


if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
  sudo -E $HOME/bin/rpi3b_led_init.sh
fi
if [ ${FMLIST_SCAN_SAVE_PWMTONE} -ne 0 ] && [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
  sleep 1
  pipwm 2000 10 0 1   50 100 50 100 50 100   150 100 150 100 150 100   50 100 50 100 50 100
fi

