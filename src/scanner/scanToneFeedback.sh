#!/bin/bash

# usage: scanToneFeedback.sh fm|dab <numFound>
if [ -z "$1" ]; then
  >&2 echo "usage: scanToneFeedback.sh welcome|fm|dab|found|saved|final|error [<numFound>]"
  exit 10
fi

case $1 in
  fm)
    # FM: short short
    pipwm 2000 10 0 1   50 100 50 300
    ;;
  dab)
    # DAB: short long
    pipwm 2000 10 0 1   50 100 300 300
    ;;
  found)
    # DAB or FM found a carrier/station
    pipwm 2000 10
    exit 0
    ;;
  welcome)
    # starting scanLoop
    pipwm 2000 10 0 1   100 100 50 100 50 100   500 100 50 100
    exit 0
    ;;
  saved)
    # saved scan results
    pipwm 2000 10 0 1   50 100 50 100 50 100   150 100 150 100 150 100
    exit 0
    ;;
  final)
    # closing/closed scanLoop
    pipwm 2000 10 0 1   50 100 50 100 50 100   150 100 150 100 150 100   50 100 50 100 50 100
    exit 0
    ;;
  error)
    # error, e.g. with RTL dongle
    pipwm 2000 500 0 1
    exit 0
    ;;
  *)
    ;;
esac

if [ $2 -ne 0 ]; then
  # short for OK - found stations
  pipwm 2000 10 0 1   100 300
else
  # long for FAIL - NO stations found
  pipwm 2000 10 0 1   300 300
fi
