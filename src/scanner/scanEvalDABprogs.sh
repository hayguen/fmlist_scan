#!/bin/bash

SCRIPT=$(realpath -s "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
source "${SCRIPTPATH}/scanEval.inc"

cat scan_*_dab_audio.csv scan_*_dab_packet.csv \
 | awk -F, '{ OFS=","; print $7,$8,$9,$10,$11; }' \
 | sort \
 |uniq
