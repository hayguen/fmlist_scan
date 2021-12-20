#!/bin/bash

SCRIPT=$(realpath -s "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
source "${SCRIPTPATH}/scanEval.inc"

cat scan_*_dab_ensemble.csv \
 | awk -F, '{ OFS=","; print $7,$8,$9; }' \
 | sort -n \
 | awk -f "${SCRIPTPATH}/uniq_count.awk" OFS=','
