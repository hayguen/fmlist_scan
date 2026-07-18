#!/bin/bash

SCRIPT=$(realpath -s "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
source "${SCRIPTPATH}/scanEval.inc"

cat scan_*_fm_rds.csv \
 | awk -F, '{
		 OFS=",";
		 pi=$13;
		 ps=$15;
		 gsub(/"/, "", pi);
		 gsub(/"/, "", ps);
		 if (ps == "________") ps = "";
		 print $3,pi,ps;
	 }' \
 | sort -n \
 | awk -f "${SCRIPTPATH}/uniq_count.awk" OFS=','
