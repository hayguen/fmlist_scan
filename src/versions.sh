#!/bin/bash

if [ "$1" = "full" ]; then
  echo -e "\nfmlist_scan:"    ; (cd .                         && git log -n 1 )
  echo -e "\nlibrtlsdr:"      ; (cd git/hayguen/librtlsdr     && git log -n 1 )
  echo -e "\ndab-cmdline:"    ; (cd git/hayguen/dab-cmdline   && git log -n 1 )
  echo -e "\neti-cmdline:"    ; (cd git/hayguen/eti-stuff     && git log -n 1 )
  echo -e "\ncsdr:"           ; (cd git/simonyiszk/csdr       && git log -n 1 )
  echo -e "\ncsdr++:"         ; (cd git/jketterl/csdr         && git log -n 1 )
  echo -e "\nredsea:"         ; (cd git/windytan/redsea       && git log -n 1 )
  echo -e "\nlib liquid-dsp:" ; (cd git/jgaeddert/liquid-dsp  && git log -n 1 )
  echo -e "\nlibcorrect:"     ; (cd git/quiet/libcorrect      && git log -n 1 )
  echo -e "\nkalibrate-rtl:"  ; (cd git/steve-m/kalibrate-rtl && git log -n 1 )
  echo -e "\ngpsd:"           ; (which gpsd && gpsd -V )
else
  #GIT_DATE_FMT="--date=iso-strict"
  GIT_DATE_FMT="--date=iso"

  d_fmlist_scan=$( cd .                   && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_librtlsdr=$( cd git/hayguen/librtlsdr && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_dabcmd=$( cd git/hayguen/dab-cmdline  && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_eticmd=$( cd git/hayguen/eti-stuff    && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_csdrs=$( cd git/simonyiszk/csdr       && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_csdrj=$( cd git/jketterl/csdr         && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_redsea=$( cd git/windytan/redsea      && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_ldsp=$( cd git/jgaeddert/liquid-dsp   && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_libcorr=$( cd git/quiet/libcorrect    && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_kalib=$( cd git/steve-m/kalibrate-rtl && git log ${GIT_DATE_FMT} -n 1 | egrep "^Date:" | sed 's/Date: //g' )
  d_gpsd=$( which gpsd )

  c_fmlist_scan=$( cd .                   && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )
  c_librtlsdr=$( cd git/hayguen/librtlsdr && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )
  c_dabcmd=$( cd git/hayguen/dab-cmdline  && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )
  c_eticmd=$( cd git/hayguen/eti-stuff    && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )
  c_csdrs=$( cd git/simonyiszk/csdr       && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )
  c_csdrj=$( cd git/jketterl/csdr         && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )
  c_redsea=$( cd git/windytan/redsea      && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )
  c_ldsp=$( cd git/jgaeddert/liquid-dsp   && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )
  c_libcorr=$( cd git/quiet/libcorrect    && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )
  c_kalib=$( cd git/steve-m/kalibrate-rtl && git log ${GIT_DATE_FMT} -n 1 | egrep "^commit" | cut -d ' ' -f 2 )
  c_gpsd=$( gpsd -V )

  if [ "$1" = "html" ]; then
    echo "<table>"
    echo "<tr><td>fmlist_scan</td><td>${c_fmlist_scan}</td><td>${d_fmlist_scan}</td></tr>"
    echo "<tr><td>librtlsdr</td><td>${c_librtlsdr}</td><td>${d_librtlsdr}</td></tr>"
    echo "<tr><td>dab-cmdline</td><td>${c_dabcmd}</td><td>${d_dabcmd}</td></tr>"
    echo "<tr><td>eti-cmdline</td><td>${c_eticmd}</td><td>${d_eticmd}</td></tr>"
    echo "<tr><td>csdr</td><td>${c_csdrs}</td><td>${d_csdrs}</td></tr>"
    echo "<tr><td>csdr++</td><td>${c_csdrj}</td><td>${d_csdrj}</td></tr>"
    echo "<tr><td>redsea</td><td>${c_redsea}</td><td>${d_redsea}</td></tr>"
    echo "<tr><td>libliquid-dsp</td><td>${c_ldsp}</td><td>${d_ldsp}</td></tr>"
    echo "<tr><td>libcorrect</td><td>${c_libcorr}</td><td>${d_libcorr}</td></tr>"
    echo "<tr><td>kalibrate-rtl</td><td>${c_kalib}</td><td>${d_kalib}</td></tr>"
    echo "<tr><td>gpsd</td><td>${c_gpsd}</td><td>${d_gpsd}</td></tr>"
    echo "</table>"
  else
    echo "fmlist_scan    ${c_fmlist_scan} ${d_fmlist_scan}"
    echo "librtlsdr      ${c_librtlsdr} ${d_librtlsdr}"
    echo "dab-cmdline    ${c_dabcmd} ${d_dabcmd}"
    echo "eti-cmdline    ${c_eticmd} ${d_eticmd}"
    echo "csdr           ${c_csdrs} ${d_csdrs}"
    echo "csdr++         ${c_csdrj} ${d_csdrj}"
    echo "redsea         ${c_redsea} ${d_redsea}"
    echo "libliquid-dsp  ${c_ldsp} ${d_ldsp}"
    echo "libcorrect     ${c_libcorr} ${d_libcorr}"
    echo "kalibrate-rtl  ${c_kalib} ${d_kalib}"
    echo "gpsd           ${c_gpsd} ${d_gpsd}"
  fi
fi
