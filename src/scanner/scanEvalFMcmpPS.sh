#!/bin/bash

SCRIPT=$(realpath -s "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
source "${SCRIPTPATH}/scanEval.inc"

cat scan_*_fm_rds.csv \
 | awk -F, '{ OFS=","; print $3,$13,$15; }' \
 | sort -n \
 | awk -f "${SCRIPTPATH}/uniq_count.awk" OFS=','
