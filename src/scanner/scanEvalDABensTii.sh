#!/bin/bash

SCRIPT=$(realpath -s "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
source "${SCRIPTPATH}/scanEval.inc"

cat scan_*_dab_ensemble.csv \
 | awk -F, '
function unquote(v) {
	gsub(/^"/, "", v)
	gsub(/"$/, "", v)
	return v
}
function add_tii_id(raw,    id, key) {
	id = unquote(raw)
	if (id == "" || id !~ /^-?[0-9]+$/) return
	id += 0
	if (id <= 0) return
	key = id
	if (!(key in seen_tii)) {
		seen_tii[key] = 1
		if (tii_out != "") tii_out = tii_out "|"
		tii_out = tii_out key
	}
}
{
	OFS=","
	tii_marker = 0
	short_label = 0
	tii_out = ""
	delete seen_tii

	for (i = 1; i <= NF; ++i) {
		field_name = unquote($i)
		if (field_name == "tii") tii_marker = i
		if (field_name == "shortLabel") {
			short_label = i
			break
		}
	}

	if (tii_marker > 0) {
		start = tii_marker + 1
		end = (short_label > 0 ? short_label - 1 : NF)

		# exTII layout: groups of 6 fields, first one is combined mainID*100+subID
		if ((end - start + 1) >= 6) {
			for (i = start; i <= end; i += 6) {
				add_tii_id($i)
			}
		}

		# legacy/mobile layout: numMostTii,numAllTii,mostTii
		if (tii_out == "" && (start + 2) <= end) {
			add_tii_id($(start + 2))
		}
	}

	print $7,$8,$9,tii_out
}' \
 | sort -n \
 | awk -f "${SCRIPTPATH}/uniq_count.awk" OFS=','
