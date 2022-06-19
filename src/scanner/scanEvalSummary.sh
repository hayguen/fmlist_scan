#!/bin/bash

SCRIPT=$(realpath -s "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
source "${SCRIPTPATH}/scanEval.inc"

if [ ! -d /dev/shm/scanEval ]; then
  mkdir /dev/shm/scanEval
fi

# based on scanEvalDABens.sh
cat scan_*_dab_ensemble.csv \
 | awk -F, '{ OFS=","; print $7,$8,$9; }' \
 | sort -n \
 | uniq \
 > /dev/shm/scanEval/dab_ensembles.csv


# based on scanEvalDABprogs.sh
cat scan_*_dab_audio.csv scan_*_dab_packet.csv \
 | awk -F, '{ OFS=","; print $7,$8,$9,$10,$11; }' \
 | sort \
 | uniq \
 > /dev/shm/scanEval/dab_programs.csv


# based on scanEvalFMcmpPI.sh
cat scan_*_fm_rds.csv \
 | awk -F, '{ OFS=","; print $3,$13; }' \
 | sort -n \
 | uniq \
 > /dev/shm/scanEval/fm_programs.csv

NUM_DAB_ENS=$( cat /dev/shm/scanEval/dab_ensembles.csv | wc -l )
NUM_DAB_PRG=$( cat /dev/shm/scanEval/dab_programs.csv  | wc -l )
NUM_FM_PRG=$(  cat /dev/shm/scanEval/fm_programs.csv   | wc -l )

echo "40, #DAB_Ensembles, ${NUM_DAB_ENS}, #DAB_Programs, ${NUM_DAB_PRG}, #FM_Programs, ${NUM_FM_PRG}"
head -n 9999 /dev/shm/scanEval/dab_ensembles.csv | awk -F, '{ OFS=","; print NR+10000, $0; }'
head -n 9999 /dev/shm/scanEval/dab_programs.csv  | awk -F, '{ OFS=","; print NR+20000, $0; }'
head -n 9999 /dev/shm/scanEval/fm_programs.csv   | awk -F, '{ OFS=","; print NR+30000, $0; }'
