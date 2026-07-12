#!/bin/bash

# one can pass a relative or absolute directory as option
SCRIPT=$(realpath -s "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
source "${SCRIPTPATH}/scanEval.inc"

# Try new format first: scan_duration.txt files in scan result directories
if find . -type f -name "scan_duration.txt" 2>/dev/null | grep -q .; then
  find . -type f -name "scan_duration.txt" -exec grep -i "duration" {} \;
# Fallback to legacy format: compressed scanner logs
elif ls *_scanner.log.gz 2>/dev/null | grep -q .; then
  zcat *_scanner.log.gz | grep -i "duration"
else
  echo "No scan duration files found (looked for scan_duration.txt or *_scanner.log.gz)"
fi
