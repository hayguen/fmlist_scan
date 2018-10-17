#!/bin/bash

source $HOME/.config/fmlist_scan/config

# check / mount
MNTC=$( mount | grep -c "${FMLIST_SCAN_RESULT_DIR}" )
if [ $MNTC -eq 0 ] && [ ${FMLIST_SCAN_MOUNT} -eq 1 ]; then

  mount "${FMLIST_SCAN_RESULT_DIR}"
  MNTC=$( mount | grep -c "${FMLIST_SCAN_RESULT_DIR}" )
  if [ $MNTC -eq 0 ]; then
    echo "Error: Device (USB memory stick) is not available on ${FMLIST_SCAN_RESULT_DIR} !"
    exit 10
  fi
fi

echo "" >"${FMLIST_SCAN_RESULT_DIR}/error.log"

if [ ${FMLIST_SCAN_MOUNT} -eq 1 ]; then
  FM=$( df -h -m ${FMLIST_SCAN_RESULT_DEV} | tail -n 1 | awk '{ print $4; }' )
  if [ $FM -le 5 ]; then
    echo "Error: not enough space on USB stick ${FMLIST_SCAN_RESULT_DEV} !"
    echo "Error: not enough space on USB stick ${FMLIST_SCAN_RESULT_DEV} !" >>"${FMLIST_SCAN_RESULT_DIR}/error.log"
    exit 10
  fi
fi

# create config folders
if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/config_old" ]; then
  mkdir "${FMLIST_SCAN_RESULT_DIR}/config_old"
fi

if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/config_new" ]; then
  mkdir "${FMLIST_SCAN_RESULT_DIR}/config_new"
fi

# copy/use new configuration - if exists
if [ $( ls -1 "${FMLIST_SCAN_RESULT_DIR}/config_new/" | wc -l ) -ne 0 ]; then
  if [ -f "${FMLIST_SCAN_RESULT_DIR}/config_new/config" ]; then
    dos2unix "${FMLIST_SCAN_RESULT_DIR}/config_new/config"
    cp "${FMLIST_SCAN_RESULT_DIR}/config_new/config" "$HOME/.config/fmlist_scan/"
  fi
  if [ -f "${FMLIST_SCAN_RESULT_DIR}/config_new/dab_chanlist.txt" ]; then
    dos2unix "${FMLIST_SCAN_RESULT_DIR}/config_new/dab_chanlist.txt"
    cp "${FMLIST_SCAN_RESULT_DIR}/config_new/dab_chanlist.txt" "$HOME/.config/fmlist_scan/"
  fi
  if [ -f "${FMLIST_SCAN_RESULT_DIR}/config_new/dabscan.inc" ]; then
    dos2unix "${FMLIST_SCAN_RESULT_DIR}/config_new/dabscan.inc"
    cp "${FMLIST_SCAN_RESULT_DIR}/config_new/dabscan.inc" "$HOME/.config/fmlist_scan/"
  fi
  if [ -f "${FMLIST_SCAN_RESULT_DIR}/config_new/fmscan.inc" ]; then
    dos2unix "${FMLIST_SCAN_RESULT_DIR}/config_new/fmscan.inc"
    cp "${FMLIST_SCAN_RESULT_DIR}/config_new/fmscan.inc" "$HOME/.config/fmlist_scan/"
  fi

  if [ -d "${FMLIST_SCAN_RESULT_DIR}/config_applied" ]; then
    rm -rf "${FMLIST_SCAN_RESULT_DIR}/config_applied"
  fi
  mv "${FMLIST_SCAN_RESULT_DIR}/config_new" "${FMLIST_SCAN_RESULT_DIR}/config_applied"
  mkdir "${FMLIST_SCAN_RESULT_DIR}/config_new"
  # re-read config
  source $HOME/.config/fmlist_scan/config
fi

cp "$HOME/.config/fmlist_scan/config"           "${FMLIST_SCAN_RESULT_DIR}/config_old/"
cp "$HOME/.config/fmlist_scan/dab_chanlist.txt" "${FMLIST_SCAN_RESULT_DIR}/config_old/"
cp "$HOME/.config/fmlist_scan/dabscan.inc"      "${FMLIST_SCAN_RESULT_DIR}/config_old/"
cp "$HOME/.config/fmlist_scan/fmscan.inc"       "${FMLIST_SCAN_RESULT_DIR}/config_old/"
sync


if [ "$1" = "autostart" ] && [ ${FMLIST_SCAN_AUTOSTART} -eq 0 ]; then
  echo "autostart is deactivated in $HOME/.config/fmlist_scan/config"
  echo "autostart is deactivated in $HOME/.config/fmlist_scan/config" >>"${FMLIST_SCAN_RESULT_DIR}/error.log"
  exit 10
fi

echo "starting screen session 'scanLoopBg' .."

screen -d -m -S scanLoopBg bash "$HOME/bin/scanLoop.sh"
sleep 2
SSESSION="$( screen -ls | grep scanLoopBg )"
if [ -z "$SSESSION" ]; then
  echo "Error starting screen session"
  echo "Error starting screen session" >>"${FMLIST_SCAN_RESULT_DIR}/error.log"
  exit 10
fi

echo "1" >$HOME/ram/scanLoopBgRunning

