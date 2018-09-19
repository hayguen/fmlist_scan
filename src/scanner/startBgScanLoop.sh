#!/bin/bash

source $HOME/.config/fmlist_scan/config

if [ "$1" = "autostart" ] && [ ${FMLIST_SCAN_AUTOSTART} -eq 0 ]; then
  echo "autostart is deactivated in $HOME/.config/fmlist_scan/config"
  exit 0
fi

echo "starting screen session 'scanLoopBg' .."

screen -d -m -S scanLoopBg bash "$HOME/bin/scanLoop.sh"
sleep 2
SSESSION="$( screen -ls | grep scanLoopBg )"
if [ -z "$SSESSION" ]; then
  echo "Error starting screen session"
fi

echo 1 >$HOME/ram/scanLoopBgRunning

