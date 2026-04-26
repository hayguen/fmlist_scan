#!/bin/bash


jsonf="$1"

PI="$(  jq ".pi"               "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/[^"]*"//' -e 's/"//g' )"
NPI="$( jq ".pi"               "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |awk '{ print $1; }' )"
PS="$(  jq ".ps"               "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/[^"]*"/"/' -e 's/,/;/g' -e 's/ /_/g' )"
APS="$( jq ".ps"               "${jsonf}" |grep -v null |uniq -c |sed -e 's/[^"]*"/"/' -e 's/,/;/g' |tr '\n' ',' )"
NPS="$( jq ".ps"               "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |awk '{ print $1; }' )"
TA="$(  jq ".ta"               "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/.*true/1/' -e 's/.*false/0/g' )"
TP="$(  jq ".tp"               "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/.*true/1/' -e 's/.*false/0/g' )"
MSC="$( jq ".is_music"         "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/.*true/1/' -e 's/.*false/0/g' )"
PTY="$( jq ".prog_type"        "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/[^"]*"/"/' -e 's/,/;/g' )"
GRP="$( jq ".group"            "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/[^"]*"/"/' -e 's/,/;/g' )"
STR="$( jq ".di.stereo"        "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/.*true/1/' -e 's/.*false/0/g' )"
DPT="$( jq ".di.dynamic_pty"   "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/.*true/1/' -e 's/.*false/0/g' )"
OPI="$( jq ".other_network.pi" "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/[^"]*"//' -e 's/"//g' )"
AF="$(jq -c ".partial_alt_frequencies" "${jsonf}" |grep -v null | awk '{ print length($0) " " $0; }' $file | sort -r -n | cut -d ' ' -f 2- | head -n 1 | sed -e 's/\[//g;s/\]//g' | sed -e 's/,/;/g')" # only use longest AF list and replace square brackets and commas, only working with parameter -p in redsea
longPS="$(jq ".long_ps"        "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/[^"]*"/"/' -e 's/,/;/g' )"
RFTapp="$(jq ".rft.app_name"   "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/[^"]*"/"/;s/,/;/g'| sed 's/\"//g' )"



# check RDS2 and print special message, if no RDS2 found, just return RT

RDS2_stream1="$( jq ".stream"  "${jsonf}" | sort | uniq | grep 1)"
RDS2_stream2="$( jq ".stream"  "${jsonf}" | sort | uniq | grep 2)"
RDS2_stream3="$( jq ".stream"  "${jsonf}" | sort | uniq | grep 3)"

if [ ${RDS2_stream1} > 0 ]; then
    RT="\"Cool! RDS2 Carriers ${RDS2_stream1},${RDS2_stream2},${RDS2_stream3} (${RFTapp}) found!! Check log & report to FMLIST\""
else
    RT="$(jq ".partial_radiotext"  "${jsonf}" |grep -v null |sort |uniq -c |sort -nr |head -n 1 |sed -e 's/[^"]*"/"/' -e 's/,/;/g' )" # partial radiotext, only possible with redsea -p parameter 
if [ "${RT}" = "" ]; then 
    RT="\"no Radiotext decoded so far\""
fi
  fi

if [ "$2" = "debug" ]; then
  echo "PI:${PI},NPI:${NPI},PS:${PS},NPS:${NPS},TA:${TA},TP:${TP},MUSIC:${MSC},PTY:${PTY},GRP:${GRP},STEREO:${STR},DYNPTY:${DPT},OTHER_PI:${OPI},"
else
  echo "${PI},${NPI},${PS},${NPS},${TA},${TP},${MSC},${PTY},${GRP},${STR},${DPT},${OPI},,,,,,,${AF},${RT}"
fi
