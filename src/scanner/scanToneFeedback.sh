#!/bin/bash

# usage: scanToneFeedback.sh fm|dab <numFound>
if [ -z "$1" ]; then
  >&2 echo "usage: scanToneFeedback.sh welcome|fm|dab|found|saved|final|error [<numFound>]"
  exit 10
fi


case $1 in
  fm|dab)
    if [ $2 -ne 0 ]; then
      # short for OK - found stations
      PARA="200 100 300"
    else
      # long for FAIL - NO stations found
      PARA="300 500 300"
    fi
    ;;
  *)
      PARA=""
    ;;
esac

case $1 in
  fm)
    # FM: short short
    pipwm 2000 10 0 1   50 100 50 ${PARA} &>/dev/null &
    exit 0
    ;;
  dab)
    # DAB: short long
    pipwm 2000 10 0 1   50 100 500 ${PARA} &>/dev/null &
    exit 0
    ;;
  found)
    # DAB or FM found a carrier/station
    pipwm 2000 10  &>/dev/null
    exit 0
    ;;
  welcome)
    # starting scanLoop
    pipwm 2000 10 0 1   100 100 50 100 50 100   500 100 50 100  &>/dev/null &
    exit 0
    ;;
  saved)
    # saved scan results
    pipwm 2000 10 0 1   50 100 50 100 50 100   150 100 150 100 150 100  &>/dev/null &
    exit 0
    ;;
  final)
    # closing/closed scanLoop
    pipwm 2000 10 0 1   50 100 50 100 50 100   150 100 150 100 150 100   50 100 50 100 50 100  &>/dev/null &
    exit 0
    ;;
  error)
    # error, e.g. with RTL dongle
    pipwm 2000 500 0 1  &>/dev/null &
    exit 0
    ;;
  *)
    ;;
esac

