#!/bin/bash

(
  echo "checking $HOME/.config/fmlist_scan/config .."
  source $HOME/.config/fmlist_scan/config

  PATH_VARS=( \
    "FMLIST_SCAN_PATH"       \
    "FMLIST_SCAN_RESULT_DIR" \
  )

  ON_OFF_VARS=( \
    "FMLIST_SCAN_RASPI"              \
    "FMLIST_SCAN_SETUP_GPS"          \
    "FMLIST_SCAN_GPS_ALL_TIME"       \
    "FMLIST_SCAN_DEAD_REBOOT"        \
    "FMLIST_SCAN_AUTO_IP_INFO"       \
    "FMLIST_SCAN_AUTO_CONFIG"        \
    "FMLIST_SCAN_AUTOSTART"          \
    "FMLIST_SCAN_FM"                 \
    "FMLIST_SCAN_DAB"                \
    "FMLIST_ALWAYS_FAST_MODE"        \
    "FMLIST_SPORADIC_E_MODE"         \
    "FMLIST_SCAN_TEST"               \
    "FMLIST_SCAN_DAB_SAVE_FIC"       \
    "FMLIST_SCAN_DAB_USE_PRESCAN"    \
    "FMLIST_SCAN_SAVE_RAW"           \
    "FMLIST_SCAN_SAVE_WAV"           \
    "FMLIST_SCAN_SAVE_RDSSPY"        \
    "FMLIST_SCAN_DEBUG"              \
    "FMLIST_SCAN_DEBUG_CHK_SPECTRUM" \
    "FMLIST_SCAN_DEBUG_REDSEA"       \
    "FMLIST_SCAN_SAVE_PWMTONE"       \
    "FMLIST_SCAN_SAVE_LEDPLAY"       \
    "FMLIST_SCAN_FOUND_PWMTONE"      \
    "FMLIST_SCAN_FOUND_LEDPLAY"      \
    "FMLIST_SCAN_PWM_FEEDBACK"       \
    "FMLIST_SCAN_MOUNT"              \
    "FMLIST_SCAN_SAVE_PARTIAL"       \
    "FMLIST_FM_DEV_R820T"            \
    "FMLIST_DAB_DEV_R820T"           \
  )

  VARS_TO_EXIST=( \
    "FMLIST_SCAN_USER"             \
    "FMLIST_USER"                  \
    "FMLIST_RASPI_ID"              \
    "FMLIST_OM_ID"                 \
    "FMLIST_SCAN_GPS_LOOP_SLEEP"   \
    "FMLIST_SCAN_DEAD_TIME"        \
    "FMLIST_SCAN_DEAD_RTL_TRIES"   \
    "FMLIST_SCAN_FM_MIN_PWR_RATIO" \
    "FMLIST_SCAN_DAB_MIN_AUTOCORR" \
    "FMLIST_QTH_PREFIX"            \
    "FMLIST_SCAN_SAVE_MINFREQ"     \
    "FMLIST_SCAN_SAVE_MAXFREQ"     \
    "FMLIST_SCAN_SAVE_MIN_MEM"     \
    "FMLIST_SCAN_WPI_LED_GREEN"    \
    "FMLIST_SCAN_WPI_LED_RED"      \
    "FMLIST_SCAN_RAM_DIR"          \
    "FMLIST_SCAN_RESULT_DSK"       \
    "FMLIST_SCAN_RESULT_DEV"       \
    "FMLIST_SCAN_PPM"              \
  )

  OTHER_VARS=( \
    "FMLIST_SCAN_GPS_COORDS" \
  )

  OPTIONAL_VARS=( \
    "FMLIST_UP_COMMENT"        \
    "FMLIST_UP_PERMISSION"     \
    "FMLIST_UP_RESTRICT_USERS" \
    "FMLIST_UP_POSITION"       \
    "FMLIST_SCAN_GPS_LAT"      \
    "FMLIST_SCAN_GPS_LON"      \
    "FMLIST_SCAN_GPS_ALT"      \
    "FMLIST_SCAN_SAVE_LOG_OPT" \
    "FMLIST_FM_RTLSDR_DEV"     \
    "FMLIST_DAB_RTLSDR_DEV"    \
  )


  M=$[ ${#PATH_VARS[@]} -1 ]
  for k in $( seq 0 $M ) ; do
    VN="${PATH_VARS[$k]}"
    VC="${!VN}"
    if [ -z "${VC}" ]; then
      echo "error: missing ${VN} in $HOME/.config/fmlist_scan/config"
    elif [ ! -d "${VC}" ]; then
      echo "error: path defined in ${VN} does not exist!"
    fi
  done

  M=$[ ${#ON_OFF_VARS[@]} -1 ]
  for k in $( seq 0 $M ) ; do
    VN="${ON_OFF_VARS[$k]}"
    VC="${!VN}"
    if [ -z "${VC}" ]; then
      echo "error: missing ${VN} in $HOME/.config/fmlist_scan/config"
    elif [ ! "${VC}" = "0" ] && [ ! "${VC}" = "1" ]; then
      echo "error: ${VN} must be '0' or '1'"
    fi
  done

  M=$[ ${#VARS_TO_EXIST[@]} -1 ]
  for k in $( seq 0 $M ) ; do
    VN="${VARS_TO_EXIST[$k]}"
    VC="${!VN}"
    if [ -z "${VC}" ]; then
      echo "error: missing ${VN} in $HOME/.config/fmlist_scan/config"
    fi
  done

  if [ -z "${FMLIST_SCAN_GPS_COORDS}" ]; then
    echo "error: missing FMLIST_SCAN_GPS_COORDS in $HOME/.config/fmlist_scan/config"
  elif [ ! "${FMLIST_SCAN_GPS_COORDS}" = "gps" ] && [ ! "${FMLIST_SCAN_GPS_COORDS}" = "static" ] && [ ! "${FMLIST_SCAN_GPS_COORDS}" = "auto" ]; then
    echo "error: FMLIST_SCAN_GPS_COORDS must be 'gps', 'static' or 'auto'"
  fi


  ALL_VARS=( "${PATH_VARS[@]}" "${ON_OFF_VARS[@]}" "${VARS_TO_EXIST[@]}" "${OTHER_VARS[@]}" "${OPTIONAL_VARS[@]}" )

  for VN in $( grep "^export" $HOME/.config/fmlist_scan/config |awk -F '=' '{ print $1; }' | awk '{ print $2; }' ) ; do
    if echo ${ALL_VARS[@]} | grep -q -w "${VN}"; then 
      echo "" >/dev/null
    else 
      echo "warning: variable ${VN} is in config - but is not registered in checkScanConfig.sh"
    fi
  done
)


(
  echo -e "\nchecking $HOME/.config/fmlist_scan/fmscan.inc .."
  source $HOME/.config/fmlist_scan/fmscan.inc

  VARS_TO_EXIST=( \
    "par_jobs"                \
    "ddc_step"                \
    "ukw_beg"                 \
    "ukw_end"                 \
    "chunkduration"           \
    "chunk2mpx_dec"           \
    "mpxsrate_chunkbw_factor" \
    "RTL_BW_OPT"              \
    "chunkduration"           \
    "RTL_BIASTEE"             \
    "RTLSDR_OPT"              \
  )

  M=$[ ${#VARS_TO_EXIST[@]} -1 ]
  for k in $( seq 0 $M ) ; do
    VN="${VARS_TO_EXIST[$k]}"
    VC="${!VN}"
    if [ -z "${VC}" ]; then
      echo "error: missing ${VN} in $HOME/.config/fmlist_scan/fmscan.inc"
    fi
  done
)


(
  echo -e "\nchecking $HOME/.config/fmlist_scan/dabscan.inc .."
  source $HOME/.config/fmlist_scan/dabscan.inc

  VARS_TO_EXIST=( \
    "chanlist"      \
    "RTL_BIASTEE"   \
    "DABOPT"        \
    "DABPRESCANOPT" \
    "DABLISTENOPT"  \
  )

  M=$[ ${#VARS_TO_EXIST[@]} -1 ]
  for k in $( seq 0 $M ) ; do
    VN="${VARS_TO_EXIST[$k]}"
    VC="${!VN}"
    if [ -z "${VC}" ]; then
      echo "error: missing ${VN} in $HOME/.config/fmlist_scan/dabscan.inc"
    fi
  done
)

