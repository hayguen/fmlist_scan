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
  export FMLIST_USER=""
fi
if [ -z "${FMLIST_OM_ID}" ]; then
  export FMLIST_OM_ID=""
fi

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
  sleep 1
done
echo -e "\n\n"

while /bin/true; do

  if [ ! -z "$1" ]; then
    echo " "
    echo "-------------------------"
    echo -e "\nstarting setup of option '$1'"
    echo "-------------------------"
    echo " "
  fi

  if [ "$1" = "syspre" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "installing system prerequisites"
    echo "-------------------------"
    echo " "
    . prereq_fmlist_scan
  fi

  if [ "$1" = "cron" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "installing crontab"
    echo "-------------------------"
    echo " "
    . prereq_crontab
  fi

  if [ "$1" = "fstab" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "installing fstab entry"
    echo "-------------------------"
    echo " "
    . prereq_fstab
  fi

  if [ "$1" = "files" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "installing scanner files"
    echo "-------------------------"
    echo " "
    . prereq_scan_files
  fi

  if [ "$1" = "conf" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "installing config files"
    echo "-------------------------"
    echo " "
    . prereq_config
  fi

  # gui software is not installed automatically
  if [ "$1" = "gui" ]; then
    echo " "
    echo "-------------------------"
    echo "installing gui software/tools"
    echo "-------------------------"
    echo " "
    . prereq_gui_software
  fi

  if [ "$1" = "pre" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "installing prerequisites"
    echo "-------------------------"
    echo " "
    . prereq_librtlsdr
    . prereq_csdr
    . prereq_liquid-dsp
    . prereq_redsea
    . prereq_dab-cmdline
    . prereq_eti-cmdline
  fi

  if [ "$1" = "gpsd" ] || [ "$1" = "" ]; then
    if [ "${FMLIST_SCAN_SETUP_GPS}" = "1" ]; then
      if [ "${FMLIST_SCAN_SETUP_GPSSRC}" = "0" ]; then
        echo " "
        echo "-------------------------"
        echo "installing gpsd from distribution"
        echo "-------------------------"
        echo " "
        apt-get -y install gpsd gpsd-clients
      elif [ "${FMLIST_SCAN_SETUP_GPSSRC}" = "1" ]; then
        echo " "
        echo "-------------------------"
        echo "installing gpsd from sources"
        echo "-------------------------"
        echo " "
        . prereq_gpsd
        sudo -u ${FMLIST_SCAN_USER} bash -c "source build_gpsd"
        . inst_gpsd
      else
        echo " "
        echo "-------------------------"
        echo "skipping gpsd installation without env FMLIST_SCAN_SETUP_GPSSRC"
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
      echo "skipping gpsd installation without env FMLIST_SCAN_SETUP_GPS = 1"
    fi
  fi

  if [ "$1" = "rtl" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building librtlsdr"
    echo "-------------------------"
    echo " "
    sudo -u ${FMLIST_SCAN_USER} bash -c "source build_librtlsdr"
    . inst_librtlsdr
  fi

  if [ "$1" = "csdr" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building csdr"
    echo "-------------------------"
    echo " "
    sudo -u ${FMLIST_SCAN_USER} bash -c "source build_csdr"
    . inst_csdr
  fi

  if [ "$1" = "lfec" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building libcorrect/libfec"
    echo "-------------------------"
    echo " "
    sudo -u ${FMLIST_SCAN_USER} bash -c "source build_libcorrect"
    . inst_libcorrect
  fi

  if [ "$1" = "ldsp" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building libliquid-dsp"
    echo "-------------------------"
    echo " "
    sudo -u ${FMLIST_SCAN_USER} bash -c "source build_liquid-dsp"
    . inst_liquid-dsp
  fi

  if [ "$1" = "redsea" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building redsea"
    echo "-------------------------"
    echo " "
    sudo -u ${FMLIST_SCAN_USER} bash -c "source build_redsea"
    . inst_redsea
  fi

  if [ "$1" = "dabcmd" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building dab-cmdline"
    echo "-------------------------"
    echo " "
    sudo -u ${FMLIST_SCAN_USER} bash -c "source build_dab-cmdline"
    . inst_dab-cmdline
  fi

  if [ "$1" = "eticmd" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building eti-cmdline"
    echo "-------------------------"
    echo " "
    sudo -u ${FMLIST_SCAN_USER} bash -c "source build_eti-cmdline"
    sudo -u ${FMLIST_SCAN_USER} bash -c "source inst_eti-cmdline"
  fi

  if [ "$1" = "pipwm" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building libwiringPi, pipwm"
    echo "-------------------------"
    echo " "
    sudo -u ${FMLIST_SCAN_USER} bash -c "source build_wiringpi"
    . inst_wpi
    sudo -u ${FMLIST_SCAN_USER} bash -c "source build_pipwm"
    . setup_pipwm
  fi

  if [ "$1" = "pishutd" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building libwiringPi, pishutdown"
    echo "-------------------------"
    echo " "
    sudo -u ${FMLIST_SCAN_USER} bash -c "source build_wiringpi"
    . inst_wpi
    sudo -u ${FMLIST_SCAN_USER} bash -c "source build_pishutdown"
    . inst_pishutdown
  fi

  if [ "$1" = "wsrv" ]; then # || [ "$1" = "" ]; then   # do not install service for now
    echo " "
    echo "-------------------------"
    echo "installing webserver files"
    echo "-------------------------"
    echo " "
    . setup_webserver
    echo " "
    echo "-------------------------"
    echo "setting up webserver for scanner"
    echo "-------------------------"
    echo " "
    . inst_webserver
  fi

  if [ "$1" = "chkspec" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building libliquid-dsp"
    echo "-------------------------"
    echo " "
    sudo -u ${FMLIST_SCAN_USER} bash -c "source build_liquid-dsp"
    . inst_liquid-dsp
    echo " "
    echo "-------------------------"
    echo "building checkSpectrumForCarrier"
    echo "-------------------------"
    echo " "
    sudo -u ${FMLIST_SCAN_USER} bash -c "source build_checkSpectrum"
  fi

  if [ "$1" = "pscan" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building prescanDAB"
    echo "-------------------------"
    echo " "
    sudo -u ${FMLIST_SCAN_USER} bash -c "source build_prescanDAB"
  fi

  if [ "$1" = "kal" ] || [ "$1" = "" ]; then
    echo " "
    echo "-------------------------"
    echo "building kal"
    sudo -u ${FMLIST_SCAN_USER} bash -c "source build_kal"
    . inst_kal
  fi

  shift
  if [ "$1" = "" ]; then
    break
  fi

done
