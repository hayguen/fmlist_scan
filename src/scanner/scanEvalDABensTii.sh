#!/bin/bash

SCRIPT=$(realpath -s "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
source "${SCRIPTPATH}/scanEval.inc"

cat scan_*_dab_ensemble.csv \
 | awk -F, '{ OFS=","; printf("%s%s%s%s%s%s",$7,OFS,$8,OFS,$9,OFS); for(i=21;i<=NF;i+=6) printf("%s%s",$i,OFS); printf("%s",RS); }' \
 | sort -n \
 | awk -f "${SCRIPTPATH}/uniq_count.awk" OFS=','
