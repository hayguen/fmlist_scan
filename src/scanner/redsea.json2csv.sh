#!/bin/bash

jsonf="$1"

PI="$(  jq ".pi"               "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/[^"]*"//' -e 's/"//g' )"
NPI="$( jq ".pi"               "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |awk '{ print $1; }' )"
PS="$(  jq ".ps"               "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/[^"]*"/"/' -e 's/,/;/g' )"
NPS="$( jq ".ps"               "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |awk '{ print $1; }' )"
TA="$(  jq ".ta"               "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/.*true/1/' -e 's/.*false/0/g' )"
TP="$(  jq ".tp"               "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/.*true/1/' -e 's/.*false/0/g' )"
MSC="$( jq ".is_music"         "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/.*true/1/' -e 's/.*false/0/g' )"
PTY="$( jq ".prog_type"        "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/[^"]*"/"/' -e 's/,/;/g' )"
GRP="$( jq ".group"            "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/[^"]*"/"/' -e 's/,/;/g' )"
STR="$( jq ".di.stereo"        "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/.*true/1/' -e 's/.*false/0/g' )"
DPT="$( jq ".di.dynamic_pty"   "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/.*true/1/' -e 's/.*false/0/g' )"
OPI="$( jq ".other_network.pi" "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/[^"]*"//' -e 's/"//g' )"

if [ "$2" = "debug" ]; then
  echo "PI:${PI},NPI:${NPI},PS:${PS},NPS:${NPS},TA:${TA},TP:${TP},MUSIC:${MSC},PTY:${PTY},GRP:${GRP},STEREO:${STR},DYNPTY:${DPT},OTHER_PI:${OPI},"
else
  echo "${PI},${NPI},${PS},${NPS},${TA},${TP},${MSC},${PTY},${GRP},${STR},${DPT},${OPI},"
fi
