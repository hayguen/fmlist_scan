#!/bin/bash

if [ "$1" = "full" ]; then
  echo -e "\nfmlist_scan:"    ; (cd .                         && git log -n 1 )
  echo -e "\nlibrtlsdr:"      ; (cd git/hayguen/librtlsdr     && git log -n 1 )
  echo -e "\ndab-cmdline:"    ; (cd git/hayguen/dab-cmdline   && git log -n 1 )
  echo -e "\neti-cmdline:"    ; (cd git/hayguen/eti-stuff     && git log -n 1 )
  echo -e "\ncsdr:"           ; (cd git/simonyiszk/csdr       && git log -n 1 )
  echo -e "\nredsea:"         ; (cd git/windytan/redsea       && git log -n 1 )
  echo -e "\nlib liquid-dsp:" ; (cd git/jgaeddert/liquid-dsp  && git log -n 1 )
  echo -e "\nlibcorrect:"     ; (cd git/quiet/libcorrect      && git log -n 1 )
  echo -e "\nkalibrate-rtl:"  ; (cd git/steve-m/kalibrate-rtl && git log -n 1 )
else
  #GIT_DATE_FMT="--date=iso-strict"
  GIT_DATE_FMT="--date=iso"

  d_fmlist_scan=$( cd .                   && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_librtlsdr=$( cd git/hayguen/librtlsdr && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_dabcmd=$( cd git/hayguen/dab-cmdline  && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_eticmd=$( cd git/hayguen/eti-stuff    && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_csdr=$( cd git/simonyiszk/csdr        && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_redsea=$( cd git/windytan/redsea      && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_ldsp=$( cd git/jgaeddert/liquid-dsp   && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_libcorr=$( cd git/quiet/libcorrect    && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_kalib=$( cd git/steve-m/kalibrate-rtl && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )

  c_fmlist_scan="  commit $( cd .                   && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )"
  c_librtlsdr="  commit $( cd git/hayguen/librtlsdr && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )"
  c_dabcmd="  commit $( cd git/hayguen/dab-cmdline  && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )"
  c_eticmd="  commit $( cd git/hayguen/eti-stuff    && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )"
  c_csdr="  commit $( cd git/simonyiszk/csdr        && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )"
  c_redsea="  commit $( cd git/windytan/redsea      && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )"
  c_ldsp="  commit $( cd git/jgaeddert/liquid-dsp   && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )"
  c_libcorr="  commit $( cd git/quiet/libcorrect    && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )"
  c_kalib="  commit $( cd git/steve-m/kalibrate-rtl && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )"

  echo "fmlist_scan:    ${d_fmlist_scan} ${c_fmlist_scan}"
  echo "librtlsdr:      ${d_librtlsdr} ${c_librtlsdr}"
  echo "dab-cmdline:    ${d_dabcmd} ${c_dabcmd}"
  echo "eti-cmdline:    ${d_eticmd} ${c_eticmd}"
  echo "csdr:           ${d_csdr} ${c_csdr}"
  echo "redsea:         ${d_redsea} ${c_redsea}"
  echo "libliquid-dsp:  ${d_ldsp} ${c_ldsp}"
  echo "libcorrect:     ${d_libcorr} ${c_libcorr}"
  echo "kalibrate-rtl:  ${d_kalib} ${c_kalib}"
fi
