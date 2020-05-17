#!/bin/bash

if [ "$1" = "full" ]; then
  GREPSTR=".*"
else
  GREPSTR="^Date:"
fi

echo -e "\nfmlist_scan:"
git log -n 1 | egrep "$GREPSTR"

echo -e "\nlibrtlsdr:"
(cd git/hayguen/librtlsdr ; git log -n 1 | egrep "$GREPSTR" )

echo -e "\ndab-cmdline:"
(cd git/hayguen/dab-cmdline ; git log -n 1 | egrep "$GREPSTR" )

echo -e "\ncsdr:"
(cd git/simonyiszk/csdr ; git log -n 1 | egrep "$GREPSTR" )

echo -e "\nredsea:"
(cd git/windytan/redsea ; git log -n 1 | egrep "$GREPSTR" )

echo -e "\nlib liquid-dsp:"
(cd git/jgaeddert/liquid-dsp ; git log -n 1 | egrep "$GREPSTR" )

echo -e "\nlibcorrect:"
(cd git/quiet/libcorrect ; git log -n 1 | egrep "$GREPSTR" )

echo -e "\nkalibrate-rtl:"
(cd git/steve-m/kalibrate-rtl ; git log -n 1 | egrep "$GREPSTR" )
