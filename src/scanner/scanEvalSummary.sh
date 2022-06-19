#!/bin/bash

export LC_ALL=C
source $HOME/.config/fmlist_scan/config

SCRIPT=$(realpath -s "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
source "${SCRIPTPATH}/scanEval.inc"

if [ ! -d /dev/shm/scanEval ]; then
  mkdir /dev/shm/scanEval
fi

# based on scanEvalDABens.sh
cat scan_*_dab_ensemble.csv \
 | awk -F, '{ OFS=","; print $7,$8,$9; }' \
 | sort \
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
 | sort \
 | uniq \
 > /dev/shm/scanEval/fm_programs.csv

NUM_DAB_ENS=$( cat /dev/shm/scanEval/dab_ensembles.csv | wc -l )
NUM_DAB_PRG=$( cat /dev/shm/scanEval/dab_programs.csv  | wc -l )
NUM_FM_PRG=$(  cat /dev/shm/scanEval/fm_programs.csv   | wc -l )

REF_DAB_ENS="0"
MIS_DAB_ENS="-"
ADD_DAB_ENS="-"
REF_DAB_PRG="0"
MIS_DAB_PRG="-"
ADD_DAB_PRG="-"
REF_FM_PRG="0"
MIS_FM_PRG="-"
ADD_FM_PRG="-"


if [ -f "${HOME}/.config/fmlist_scan/${FMLIST_QTH_PREFIX}_dab_ensembles.csv" ]; then
  REF_DAB_ENS=$( cat "${HOME}/.config/fmlist_scan/${FMLIST_QTH_PREFIX}_dab_ensembles.csv" | wc -l )
  if [ ${REF_DAB_ENS} -gt 0 ]; then
    comm -13 /dev/shm/scanEval/dab_ensembles.csv "${HOME}/.config/fmlist_scan/${FMLIST_QTH_PREFIX}_dab_ensembles.csv" >/dev/shm/scanEval/missing_dab_ensembles.csv
    comm -23 /dev/shm/scanEval/dab_ensembles.csv "${HOME}/.config/fmlist_scan/${FMLIST_QTH_PREFIX}_dab_ensembles.csv" >/dev/shm/scanEval/additional_dab_ensembles.csv
    MIS_DAB_ENS=$( cat /dev/shm/scanEval/missing_dab_ensembles.csv    | wc -l )
    ADD_DAB_ENS=$( cat /dev/shm/scanEval/additional_dab_ensembles.csv | wc -l )
  fi
fi

if [ -f "${HOME}/.config/fmlist_scan/${FMLIST_QTH_PREFIX}_dab_programs.csv" ]; then
  REF_DAB_PRG=$( cat "${HOME}/.config/fmlist_scan/${FMLIST_QTH_PREFIX}_dab_programs.csv" | wc -l )
  if [ ${REF_DAB_PRG} -gt 0 ]; then
    comm -13 /dev/shm/scanEval/dab_programs.csv "${HOME}/.config/fmlist_scan/${FMLIST_QTH_PREFIX}_dab_programs.csv" >/dev/shm/scanEval/missing_dab_programs.csv
    comm -23 /dev/shm/scanEval/dab_programs.csv "${HOME}/.config/fmlist_scan/${FMLIST_QTH_PREFIX}_dab_programs.csv" >/dev/shm/scanEval/additional_dab_programs.csv
    MIS_DAB_PRG=$( cat /dev/shm/scanEval/missing_dab_programs.csv    | wc -l )
    ADD_DAB_PRG=$( cat /dev/shm/scanEval/additional_dab_programs.csv | wc -l )
  fi
fi

if [ -f "${HOME}/.config/fmlist_scan/${FMLIST_QTH_PREFIX}_fm_programs.csv" ]; then
  REF_FM_PRG=$( cat "${HOME}/.config/fmlist_scan/${FMLIST_QTH_PREFIX}_fm_programs.csv" | wc -l )
  if [ ${REF_FM_PRG} -gt 0 ]; then
    comm -13 /dev/shm/scanEval/fm_programs.csv "${HOME}/.config/fmlist_scan/${FMLIST_QTH_PREFIX}_fm_programs.csv" >/dev/shm/scanEval/missing_fm_programs.csv
    comm -23 /dev/shm/scanEval/fm_programs.csv "${HOME}/.config/fmlist_scan/${FMLIST_QTH_PREFIX}_fm_programs.csv" >/dev/shm/scanEval/additional_fm_programs.csv
    MIS_FM_PRG=$( cat /dev/shm/scanEval/missing_fm_programs.csv    | wc -l )
    ADD_FM_PRG=$( cat /dev/shm/scanEval/additional_fm_programs.csv | wc -l )
  fi
fi

echo "40, scanned 10k #DAB_Ensembles, ${NUM_DAB_ENS}, 20k #DAB_Programs, ${NUM_DAB_PRG}, 30k #FM_Programs, ${NUM_FM_PRG}"
echo "43, reference #DAB_Ensembles, ${REF_DAB_ENS}, #DAB_Programs, ${REF_DAB_PRG}, #FM_Programs, ${REF_FM_PRG}"
echo "41, missing 40k #DAB_Ensembles, ${MIS_DAB_ENS}, 50k #DAB_Programs, ${MIS_DAB_PRG}, 60k #FM_Programs, ${MIS_FM_PRG}"
echo "42, additional 70k #DAB_Ensembles, ${ADD_DAB_ENS}, 80k #DAB_Programs, ${ADD_DAB_PRG}, 90k #FM_Programs, ${ADD_FM_PRG}"


if [ -z "${SKIP_SCANNED}" ]; then
head -n 9999 /dev/shm/scanEval/dab_ensembles.csv 2>/dev/null | awk -F, '{ OFS=","; print NR+10000, $0; }'
head -n 9999 /dev/shm/scanEval/dab_programs.csv  2>/dev/null | awk -F, '{ OFS=","; print NR+20000, $0; }'
head -n 9999 /dev/shm/scanEval/fm_programs.csv   2>/dev/null | awk -F, '{ OFS=","; print NR+30000, $0; }'
fi

if [ -z "${SKIP_MISSING}" ]; then
head -n 9999 /dev/shm/scanEval/missing_dab_ensembles.csv 2>/dev/null | awk -F, '{ OFS=","; print NR+40000, $0; }'
head -n 9999 /dev/shm/scanEval/missing_dab_programs.csv  2>/dev/null | awk -F, '{ OFS=","; print NR+50000, $0; }'
head -n 9999 /dev/shm/scanEval/missing_fm_programs.csv   2>/dev/null | awk -F, '{ OFS=","; print NR+60000, $0; }'
fi

if [ -z "${SKIP_ADD}" ]; then
head -n 9999 /dev/shm/scanEval/additional_dab_ensembles.csv 2>/dev/null | awk -F, '{ OFS=","; print NR+70000, $0; }'
head -n 9999 /dev/shm/scanEval/additional_dab_programs.csv  2>/dev/null | awk -F, '{ OFS=","; print NR+80000, $0; }'
head -n 9999 /dev/shm/scanEval/additional_fm_programs.csv   2>/dev/null | awk -F, '{ OFS=","; print NR+90000, $0; }'
fi

