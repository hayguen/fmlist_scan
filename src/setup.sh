#!/bin/bash

if [ ! "$(whoami)" = "root" ]; then
    echo " "
    echo "-------------------------"
    echo "$0 must be called as root or with sudo"
    echo "-------------------------"
    echo " "
  exit 0
fi

if [ -z "${FMLIST_SCAN_USER}" ]; then
  export FMLIST_SCAN_USER="pi"
fi
if [ -z "${FMLIST_SCAN_RASPI}" ]; then
  export FMLIST_SCAN_RASPI="1"
fi
if [ -z "${FMLIST_SCAN_SETUP_GPS}" ]; then
  export FMLIST_SCAN_SETUP_GPS="1"
fi
if [ -z "${FMLIST_SCAN_SETUP_GPSSRC}" ]; then
  export FMLIST_SCAN_SETUP_GPSSRC="0"
fi

if [ -z "${FMLIST_SCAN_MOUNT}" ]; then
  export FMLIST_SCAN_MOUNT="1"
fi
if [ -z "${FMLIST_SCAN_RESULT_DEV}" ]; then
  export FMLIST_SCAN_RESULT_DEV="/dev/sda1"
fi
if [ -z "${FMLIST_SCAN_RESULT_DIR}" ]; then
  export FMLIST_SCAN_RESULT_DIR="/mnt/sda1"
fi

if [ -z "${FMLIST_USER}" ]; then
  echo " "
  echo "-------------------------"
  echo "warning: FMLIST_USER is not set"
  echo "please uncomment and set FMLIST_USER in setup.sh before running this script"
  echo "-------------------------"
  echo " "
  exit 1
fi
if [ -z "${FMLIST_OM_ID}" ]; then
  export FMLIST_OM_ID=""
fi

on_setup_interrupt() {
  echo " "
  echo "========================================="
  echo "SETUP STOPPED BY USER"
  echo "  received interrupt signal (Ctrl-C)"
  echo "========================================="
  exit 130
}

handle_step_failure() {
  local rc="$1"
  if [ "${rc}" -eq 130 ]; then
    on_setup_interrupt
  fi
}

trap on_setup_interrupt INT TERM

echo "$0 [syspre|cron|fstab|files|conf|pre|gui|rtl|csdr|lfec|ldsp|redsea|dabcmd|eticmd|pipwm|pishutd|wsrv|chkspec|pscan|kal|gpsd]"
echo "  syspre  install system prerequisites"
echo "  cron    install crontab entries"
echo "  fstab   install fstab entry"
echo "  files   install scanner files"
echo "  conf    install config files in ~/.config/fmlist_scan/"
echo "  pre     install prerequisites for all tools to be compiled"
echo "  gui     install gui software/tools"
echo "  rtl     install prerequisites, build & install librtlsdr - rtlsdr 'driver' lib"
echo "  csdr    install prerequisites, build & install for csdr - sdr command line tools"
echo "  lfec    install prerequisites, build & install for libfec aka libcorrect - required from liquid-dsp"
echo "  ldsp    install prerequisites, build & install for liquid-dsp - required from redsea"
echo "  redsea  install prerequisites, build & install for redsea - rds decoder"
echo "  dabcmd  install prerequisites, build & install for dab-cmdline - dab decoder - modified for scan"
echo "  eticmd  install prerequisites, build & install for eti-cmdline"
echo "  pipwm   build & install libwiringPi. then compile / install pipwm"
echo "  pishutd build & install libwiringPi. then compile / install pishutdown"
echo "  wsrv    install webserver for scanner"
echo "  chkspec build & install liquid-dsp. then compile / install checkSpectrumForCarrier"
echo "  pscan   compile / install prescanDAB"
echo "  kal     build & install kal"
echo "  gpsd    build & install gpsd - system - or from source"
echo ""
echo "environment parameters - to set before calling:"
echo "set export FMLIST_SCAN_USER=<user>   # default user \"pi\""
echo "set export FMLIST_SCAN_RASPI=<1/0>   # default \"1\" if Raspberry Pi hardware"
echo ""


if [ "$1" = "-h" ] || [ "$1" = "--h" ] || [ "$1" = "--help" ]; then
  exit 0
fi

if [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"   
    echo "will install/build ALL (except gui) - without parameters"
    echo "-------------------------"
    echo " "
else
    echo " "
    echo "-------------------------"
    echo "will install/build selected options: $*"
    echo "-------------------------"
    echo " "
fi
for C in $(seq 5 -1 1) ; do
  echo -en "\r${C} secs to start .. press Ctrl-C to abort"
  sleep 1 || on_setup_interrupt
done
echo -e "\n\n"

FAILED_STEPS=()
SUCCESS_STEPS=()

while /bin/true; do

  if [ ! -z "$1" ]; then
    echo " "
    echo "-------------------------"
    echo -e "starting setup of option '$1'"
    echo "-------------------------"
    echo " "
  fi

  if [ "$1" = "syspre" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "installing system prerequisites"
    echo "-------------------------"
    echo " "
    if . prereq_fmlist_scan; then
        SUCCESS_STEPS+=("syspre")
    else
        FAILED_STEPS+=("syspre")
    fi
  fi

  if [ "$1" = "cron" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "installing crontab"
    echo "-------------------------"
    echo " "
    if . prereq_crontab; then
        SUCCESS_STEPS+=("cron")
    else
        FAILED_STEPS+=("cron")
    fi
  fi

  if [ "$1" = "fstab" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "installing fstab entry"
    echo "-------------------------"
    echo " "
    if . prereq_fstab; then
        SUCCESS_STEPS+=("fstab")
    else
        FAILED_STEPS+=("fstab")
    fi
  fi

  if [ "$1" = "files" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "installing scanner files"
    echo "-------------------------"
    echo " "
    if . prereq_scan_files; then
        SUCCESS_STEPS+=("files")
    else
        FAILED_STEPS+=("files")
    fi
  fi

  if [ "$1" = "conf" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "installing config files"
    echo "-------------------------"
    echo " "
    if . prereq_config; then
        SUCCESS_STEPS+=("conf")
    else
        FAILED_STEPS+=("conf")
    fi
  fi

  # gui software is not installed automatically
  if [ "$1" = "gui" ]; then
    echo " "
    echo "-------------------------"
    echo "installing gui software/tools"
    echo "-------------------------"
    echo " "
    if . prereq_gui_software; then
        SUCCESS_STEPS+=("gui")
    else
        FAILED_STEPS+=("gui")
    fi
  fi

  if [ "$1" = "pre" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "installing prerequisites"
    echo "-------------------------"
    echo " "
    if . prereq_librtlsdr && . prereq_csdr && . prereq_liquid-dsp && . prereq_redsea && . prereq_dab-cmdline && . prereq_eti-cmdline; then
        SUCCESS_STEPS+=("pre")
    else
        FAILED_STEPS+=("pre")
    fi
  fi

  if [ "$1" = "gpsd" ] || [ "$1" = "" ]; then
    if [ "${FMLIST_SCAN_SETUP_GPS}" = "1" ]; then
      if [ "${FMLIST_SCAN_SETUP_GPSSRC}" = "0" ]; then
        echo " "
        echo "-------------------------"
        echo "installing gpsd from distribution"
        echo "-------------------------"
        echo " "
        if apt-get -y install gpsd gpsd-clients; then
            SUCCESS_STEPS+=("gpsd")
        else
            FAILED_STEPS+=("gpsd")
        fi
      elif [ "${FMLIST_SCAN_SETUP_GPSSRC}" = "1" ]; then
        echo " "
        echo "-------------------------"
        echo "installing gpsd from sources"
        echo "-------------------------"
        echo " "
        if . prereq_gpsd && sudo -u ${FMLIST_SCAN_USER} bash -c "source build_gpsd" && . inst_gpsd; then
            SUCCESS_STEPS+=("gpsd")
        else
            FAILED_STEPS+=("gpsd")
        fi
      else
        echo " "
        echo "-------------------------"
        echo "skipping gpsd installation without env FMLIST_SCAN_SETUP_GPSSRC"
        echo "-------------------------"
        echo " "
      fi
        echo " "
        echo "-------------------------"
        echo "stopping gpsd services gpsd.socket and gpsd.service with systemctl"
        echo "-------------------------"
        echo " "
      systemctl stop gpsd.service
      systemctl stop gpsd.socket
      echo " "
      echo "-------------------------"
      echo "setup gpsd defaults to /etc/default/gpsd"
      echo "-------------------------"
      echo " "
      cp gpsd.conf /etc/default/gpsd
      systemctl daemon-reload
      systemctl enable gpsd.socket
      systemctl enable gpsd.service
    else
      echo " "
      echo "-------------------------"
      echo "skipping gpsd installation without env FMLIST_SCAN_SETUP_GPS = 1"
      echo "-------------------------"
      echo " "
    fi
  fi

  if [ "$1" = "rtl" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building librtlsdr"
    echo "-------------------------"
    echo " "
    if sudo -u ${FMLIST_SCAN_USER} bash -c "source build_librtlsdr" && . inst_librtlsdr; then
        SUCCESS_STEPS+=("rtl")
    else
      handle_step_failure $?
        FAILED_STEPS+=("rtl")
    fi
  fi

  if [ "$1" = "csdr" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building csdr"
    echo "-------------------------"
    echo " "
    if sudo -u ${FMLIST_SCAN_USER} bash -c "source build_csdr" && . inst_csdr; then
        SUCCESS_STEPS+=("csdr")
    else
      handle_step_failure $?
        FAILED_STEPS+=("csdr")
    fi    
  fi

  if [ "$1" = "lfec" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building libcorrect/libfec"
    echo "-------------------------"
    echo " "
    if sudo -u ${FMLIST_SCAN_USER} bash -c "source build_libcorrect" && . inst_libcorrect; then
        SUCCESS_STEPS+=("lfec")
    else
      handle_step_failure $?
        FAILED_STEPS+=("lfec")
    fi
  fi

  if [ "$1" = "ldsp" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building libliquid-dsp"
    echo "-------------------------"
    echo " "
    if sudo -u ${FMLIST_SCAN_USER} bash -c "source build_liquid-dsp" && . inst_liquid-dsp; then
        SUCCESS_STEPS+=("ldsp")
    else
      handle_step_failure $?
        FAILED_STEPS+=("ldsp")
    fi
  fi

  if [ "$1" = "redsea" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building redsea"
    echo "-------------------------"
    echo " "
    if sudo -u ${FMLIST_SCAN_USER} bash -c "source build_redsea" && . inst_redsea; then
        SUCCESS_STEPS+=("redsea")
    else
      handle_step_failure $?
        FAILED_STEPS+=("redsea")
    fi
  fi

  if [ "$1" = "dabcmd" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building dab-cmdline"
    echo "-------------------------"
    echo " "
    if sudo -u ${FMLIST_SCAN_USER} bash -c "source build_dab-cmdline" && . inst_dab-cmdline; then
        SUCCESS_STEPS+=("dabcmd")
    else
      handle_step_failure $?
        FAILED_STEPS+=("dabcmd")
    fi
  fi

  if [ "$1" = "eticmd" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building eti-cmdline"
    echo "-------------------------"
    echo " "
    if sudo -u ${FMLIST_SCAN_USER} bash -c "source build_eti-cmdline" && sudo -u ${FMLIST_SCAN_USER} bash -c "source inst_eti-cmdline"; then
        SUCCESS_STEPS+=("eticmd")
    else
      handle_step_failure $?
        FAILED_STEPS+=("eticmd")
    fi
  fi

  if [ "$1" = "pipwm" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building libwiringPi, pipwm"
    echo "-------------------------"
    echo " "
    if sudo -u ${FMLIST_SCAN_USER} bash -c "source build_wiringpi" && . inst_wpi && sudo -u ${FMLIST_SCAN_USER} bash -c "source build_pipwm" && . setup_pipwm; then
        SUCCESS_STEPS+=("pipwm")
    else
      handle_step_failure $?
        FAILED_STEPS+=("pipwm")
    fi
  fi

  if [ "$1" = "pishutd" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building libwiringPi, pishutdown"
    echo "-------------------------"
    echo " "
    if sudo -u ${FMLIST_SCAN_USER} bash -c "source build_wiringpi" && . inst_wpi && sudo -u ${FMLIST_SCAN_USER} bash -c "source build_pishutdown" && . inst_pishutdown; then
        SUCCESS_STEPS+=("pishutd")
    else
      handle_step_failure $?
        FAILED_STEPS+=("pishutd")
    fi
  fi

  if [ "$1" = "wsrv" ] || [ "$1" = "" ]; then   # install webserver by default
    echo " "
    echo "-------------------------"
    echo "installing webserver files"
    echo "-------------------------"
    echo " "
    echo " "
    echo "-------------------------"
    echo "setting up webserver for scanner"
    echo "-------------------------"
    echo " "
    if . setup_webserver && . inst_webserver; then
        SUCCESS_STEPS+=("wsrv")
    else
        FAILED_STEPS+=("wsrv")
    fi
  fi

  if [ "$1" = "chkspec" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building libliquid-dsp"
    echo "-------------------------"
    echo " "
    echo " "
    echo "-------------------------"
    echo "building checkSpectrumForCarrier"
    echo "-------------------------"
    echo " "
    if sudo -u ${FMLIST_SCAN_USER} bash -c "source build_liquid-dsp" && . inst_liquid-dsp && sudo -u ${FMLIST_SCAN_USER} bash -c "source build_checkSpectrum"; then
        SUCCESS_STEPS+=("chkspec")
    else
      handle_step_failure $?
        FAILED_STEPS+=("chkspec")
    fi
  fi

  if [ "$1" = "pscan" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building prescanDAB"
    echo "-------------------------"
    echo " "
    if sudo -u ${FMLIST_SCAN_USER} bash -c "source build_prescanDAB"; then
        SUCCESS_STEPS+=("pscan")
    else
      handle_step_failure $?
        FAILED_STEPS+=("pscan")
    fi
  fi

  if [ "$1" = "kal" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building kal"
    echo "-------------------------"
    echo " "

    if sudo -u ${FMLIST_SCAN_USER} bash -c "source build_kal" && . inst_kal; then
        SUCCESS_STEPS+=("kal")
    else
      handle_step_failure $?
        FAILED_STEPS+=("kal")
    fi
  fi

  shift
  if [ "$1" = "" ]; then
    break
  fi

done

echo " "
echo "========================================="
if [ ${#FAILED_STEPS[@]} -eq 0 ]; then
    echo "✓ SETUP COMPLETED SUCCESSFULLY"
    echo "  All ${#SUCCESS_STEPS[@]} steps completed without errors"
    exit 0
else
    echo "✗ SETUP COMPLETED WITH ERRORS"
    echo "  Failed steps: ${FAILED_STEPS[*]}"
    echo "  Successful steps: ${SUCCESS_STEPS[*]}"
    exit 1
fi
echo "========================================="
