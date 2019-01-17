#!/bin/bash

source "$HOME/.config/fmlist_scan/config"
source "$HOME/.config/fmlist_scan/dabscan.inc"

if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

chan="$1"

if [ -z "${chan}" ] || [ "${chan}" = "-h" ] || [ "${chan}" = "--help" ]; then
  echo "usage: $0 <channel> [<additional options to dab-rtlsdr>]"
  exit 0
fi

if [ -f "${FMLIST_SCAN_RAM_DIR}/scanLoopBgRunning" ]; then
  echo "scanLoop is running! stop with 'stopBgScanLoop.sh' for recording"
  exit 10
fi

if [ -z "${chan}" ]; then
  echo "invalid dab channel in argument 1"
  exit 0
fi

echo "control volume with amixer set <control> 90%"
echo "starting   dab-rtlsdr ${DABLISTENOPT} -P Dlf -C $@ | aplay -r 48000 -f S16_LE -t raw -c 2 .."

# dab-rtlsdr -Q -W 5000 -A 6000 -c -t 5 -a 0.8 -r 5 -x -P Dlf -C "$@" | aplay -r 48000 -f S16_LE -t raw -c 2
dab-rtlsdr ${DABLISTENOPT} -P Dlf -C "$@" | aplay -r 48000 -f S16_LE -t raw -c 2

