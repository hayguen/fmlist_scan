#!/bin/bash

source $HOME/.config/fmlist_scan/config

if [ -z "$1" ]; then
  >&2 echo "usage $0 <filetype> [<date> [<begin> [<end>]]]"
  >&2 echo -e "\tconcatenates file contents within one dates given time region"
  >&2 echo -e "\tfiletype  filename part in scanner result directory: 'cputemp', 'gpscoor' or 'fm'."
  >&2 echo -e "\tdate      date in format 'YYY-mm-dd', e.g. '2018-09-17'"
  >&2 echo -e "\tbegin     optional begin time in numeric format 'hhmmss', e.g. '010203'. default: '000000'"
  >&2 echo -e "\tend       optional end time in numeric format 'hhmmss'. default: '235959'"
  exit 10
fi

FTYPE="$1"
if [ -z "$2" ]; then
  DT="$(date -u "+%Y-%m-%d")"
else
  DT="$2"
fi
# append a "1" to prevent sed producing an empty string,
# producing error in if comparisons
if [ -z "$3" ]; then
  TBEG="1"
else
  TBEG="$( echo -n "${3}1" |sed 's/^0*//' )"
fi
if [ -z "$4" ]; then
  TEND="2359591"
else
  TEND="$( echo -n "${4}1" |sed 's/^0*//' )"
fi

cd "${FMLIST_SCAN_RESULT_DIR}/${DT}"
find . -iname "scan_${DT}T*_${FTYPE}.csv" |sort |while read f ; do
  # 0        1        12   2     3
  # 1234567890123456789012345678901234567890
  # ./scan_2018-09-17T033950_gpscoor.csv
  T="$(echo -n "$f" |cut -c 19-24 |sed 's/^0*//')1"
  if [ $T -gt $TEND ]; then
    break
  fi
  if [ $T -ge $TBEG ]; then
    cat "$f"
    ST="${PIPESTATUS[0]}"
    if [ ! "$ST" = "0" ]; then
      break
    fi
  fi
done

