#!/bin/bash

# usage: scanToneFeedback.sh fm|dab <numFound>

case $1 in
  fm)
    # FM: short short
    pipwm 2000 10 0 1   50 100 50 300
    ;;
  dab)
    # DAB: short long
    pipwm 2000 10 0 1   50 100 300 300
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
