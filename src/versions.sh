#!/bin/bash

if [ "$1" = "full" ]; then
  echo -e "\nfmlist_scan:"    ; (cd .                         && git log -n 1 )
  echo -e "\nlibrtlsdr:"      ; (cd git/hayguen/librtlsdr     && git log -n 1 )
  echo -e "\ndab-cmdline:"    ; (cd git/hayguen/dab-cmdline   && git log -n 1 )
  echo -e "\neti-cmdline:"    ; (cd git/hayguen/eti-stuff     && git log -n 1 )
#  echo -e "\ncsdr:"           ; (cd git/simonyiszk/csdr       && git log -n 1 )  # no more necessary
  echo -e "\ncsdr++:"         ; (cd git/jketterl/csdr         && git log -n 1 )
  echo -e "\nredsea:"         ; (cd git/windytan/redsea       && git log -n 1 )
  echo -e "\nlib liquid-dsp:" ; (cd git/jgaeddert/liquid-dsp  && git log -n 1 )
  echo -e "\nlibcorrect:"     ; (cd git/quiet/libcorrect      && git log -n 1 )
  echo -e "\nkalibrate-rtl:"  ; (cd git/steve-m/kalibrate-rtl && git log -n 1 )
  echo -e "\ngpsd:"           ; (sudo bash -l -c "which gpsd" && sudo bash -l -c "gpsd -V" )
  echo -e "\nos-release:"     ; (source /etc/os-release; echo "$PRETTY_NAME" )
  echo -e "\narchitecture:"   ; arch
else
  GIT_DATE_FMT="--date=short"
  GIT_LOG_FMT="--pretty=format:%h %cd %<(55,trunc)%s"

  s_fmlist_scan=$( cd .                   && git log -n 1 ${GIT_DATE_FMT} "${GIT_LOG_FMT}" )
  s_librtlsdr=$( cd git/hayguen/librtlsdr && git log -n 1 ${GIT_DATE_FMT} "${GIT_LOG_FMT}" )
  s_dabcmd=$( cd git/hayguen/dab-cmdline  && git log -n 1 ${GIT_DATE_FMT} "${GIT_LOG_FMT}" )
  s_eticmd=$( cd git/hayguen/eti-stuff    && git log -n 1 ${GIT_DATE_FMT} "${GIT_LOG_FMT}" )
#  s_csdrs=$( cd git/simonyiszk/csdr       && git log -n 1 ${GIT_DATE_FMT} "${GIT_LOG_FMT}" )
  s_csdrj=$( cd git/jketterl/csdr         && git log -n 1 ${GIT_DATE_FMT} "${GIT_LOG_FMT}" )
  s_redsea=$( cd git/windytan/redsea      && git log -n 1 ${GIT_DATE_FMT} "${GIT_LOG_FMT}" )
  s_ldsp=$( cd git/jgaeddert/liquid-dsp   && git log -n 1 ${GIT_DATE_FMT} "${GIT_LOG_FMT}" )
  s_libcorr=$( cd git/quiet/libcorrect    && git log -n 1 ${GIT_DATE_FMT} "${GIT_LOG_FMT}" )
  s_kalib=$( cd git/steve-m/kalibrate-rtl && git log -n 1 ${GIT_DATE_FMT} "${GIT_LOG_FMT}" )

  d_gpsd=$( sudo bash -l -c "which gpsd" )
  c_gpsd=$( sudo bash -l -c "gpsd -V" )
  c_os_rel=$( (source /etc/os-release ; echo "$PRETTY_NAME" ) )
  c_arch=$( arch )

  if [ "$1" = "html" ]; then
    H_GIT_DATE_FMT="--date=short"
    H_GIT_LOG_FMT="--pretty=format:%h|%cd|%s"

    h_fmlist_scan=$( cd .                   && git log -n 1 ${H_GIT_DATE_FMT} "${H_GIT_LOG_FMT}" )
    h_librtlsdr=$( cd git/hayguen/librtlsdr && git log -n 1 ${H_GIT_DATE_FMT} "${H_GIT_LOG_FMT}" )
    h_dabcmd=$( cd git/hayguen/dab-cmdline  && git log -n 1 ${H_GIT_DATE_FMT} "${H_GIT_LOG_FMT}" )
    h_eticmd=$( cd git/hayguen/eti-stuff    && git log -n 1 ${H_GIT_DATE_FMT} "${H_GIT_LOG_FMT}" )
#    h_csdrs=$( cd git/simonyiszk/csdr       && git log -n 1 ${H_GIT_DATE_FMT} "${H_GIT_LOG_FMT}" )
    h_csdrj=$( cd git/jketterl/csdr         && git log -n 1 ${H_GIT_DATE_FMT} "${H_GIT_LOG_FMT}" )
    h_redsea=$( cd git/windytan/redsea      && git log -n 1 ${H_GIT_DATE_FMT} "${H_GIT_LOG_FMT}" )
    h_ldsp=$( cd git/jgaeddert/liquid-dsp   && git log -n 1 ${H_GIT_DATE_FMT} "${H_GIT_LOG_FMT}" )
    h_libcorr=$( cd git/quiet/libcorrect    && git log -n 1 ${H_GIT_DATE_FMT} "${H_GIT_LOG_FMT}" )
    h_kalib=$( cd git/steve-m/kalibrate-rtl && git log -n 1 ${H_GIT_DATE_FMT} "${H_GIT_LOG_FMT}" )

    print_html_row() {
      local repo="$1"
      local raw="$2"
      local hash rest date subj
      hash="${raw%%|*}"
      rest="${raw#*|}"
      date="${rest%%|*}"
      subj="${rest#*|}"
      echo "<tr><td>${repo}</td><td>${hash}</td><td>${date}</td><td>${subj}</td></tr>"
    }

    echo "<style>"
    echo ".versions-wrap{max-width:100%;overflow-x:auto;-webkit-overflow-scrolling:touch;}"
    echo "table.versions{border-collapse:collapse;width:100%;min-width:720px;}"
    echo "table.versions th,table.versions td{padding:4px 8px;border-bottom:1px solid #ddd;text-align:left;vertical-align:top;}"
    echo "table.versions td:nth-child(4){word-break:break-word;}"
    echo "@media (max-width:700px){table.versions{font-size:12px;min-width:560px;} table.versions th,table.versions td{padding:3px 6px;}}"
    echo "</style>"
    echo "<div class=\"versions-wrap\">"
    echo "<table class=\"versions\">"
    echo "<tr><th>Repository</th><th>Commit</th><th>Date</th><th>Message</th></tr>"
    print_html_row "fmlist_scan" "${h_fmlist_scan}"
    print_html_row "librtlsdr" "${h_librtlsdr}"
    print_html_row "dab-cmdline" "${h_dabcmd}"
    print_html_row "eti-cmdline" "${h_eticmd}"
#    print_html_row "csdr" "${h_csdrs}"
    print_html_row "csdr++" "${h_csdrj}"
    print_html_row "redsea" "${h_redsea}"
    print_html_row "libliquid-dsp" "${h_ldsp}"
    print_html_row "libcorrect" "${h_libcorr}"
    print_html_row "kalibrate-rtl" "${h_kalib}"
    echo "<tr><td>gpsd-version</td><td></td><td></td><td>${c_gpsd}</td></tr>"
    echo "<tr><td>gpsd-path</td><td></td><td></td><td>${d_gpsd}</td></tr>"
    echo "<tr><td>os-release</td><td></td><td></td><td>${c_os_rel}</td></tr>"
    echo "<tr><td>architecture</td><td></td><td></td><td>${c_arch}</td></tr>"
    echo "</table>"
    echo "</div>"
  else
    echo "fmlist_scan    ${s_fmlist_scan}"
    echo "librtlsdr      ${s_librtlsdr}"
    echo "dab-cmdline    ${s_dabcmd}"
    echo "eti-cmdline    ${s_eticmd}"
#    echo "csdr           ${s_csdrs}"
    echo "csdr++         ${s_csdrj}"
    echo "redsea         ${s_redsea}"
    echo "libliquid-dsp  ${s_ldsp}"
    echo "libcorrect     ${s_libcorr}"
    echo "kalibrate-rtl  ${s_kalib}"
    echo "gpsd           ${c_gpsd} ${d_gpsd}"
    echo "os-release     ${c_os_rel}"
    echo "architecture   ${c_arch}"
  fi
fi
