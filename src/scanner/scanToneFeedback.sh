#!/bin/bash

# usage: scanToneFeedback.sh fm|dab <numFound>
if [ -z "$1" ]; then
  >&2 echo "usage: scanToneFeedback.sh welcome|fm|dab|found|saved|final|error [<numFound>]"
  exit 10
fi

echo -e "\ncalled $0 $1"

# default
FREQ="2000"
MODE="1"
#
#FREQ="950"
#MODE="2"

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
    pipwm.sh "$1" ${FREQ} 10 0 ${MODE}   50 100 50 ${PARA} &
    exit 0
    ;;
  dab)
    # DAB: short long
    pipwm.sh "$1" ${FREQ} 10 0 ${MODE}   50 100 500 ${PARA}  &
    exit 0
    ;;
  found)
    # DAB or FM found a carrier/station
    pipwm.sh "$1" ${FREQ} 100 0 ${MODE} &
    exit 0
    ;;
  welcome)
    # starting scanLoop
    pipwm.sh "$1" ${FREQ} 10 0 ${MODE}   100 100 50 100 50 100   500 100 50 100  &
    exit 0
    ;;
  saved)
    # saved scan results
    pipwm.sh "$1" ${FREQ} 10 0 ${MODE}   50 100 50 100 50 100   150 100 150 100 150 100  &
    exit 0
    ;;
  final)
    # closing/closed scanLoop
    pipwm.sh "$1" ${FREQ} 10 0 ${MODE}   50 100 50 100 50 100   150 100 150 100 150 100   50 100 50 100 50 100  &
    exit 0
    ;;
  error)
    # error, e.g. with RTL dongle
    pipwm.sh "$1" ${FREQ} 500 0 ${MODE}  &
    exit 0
    ;;
  *)
    ;;
esac

