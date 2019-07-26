#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

# check / mount
MNTC=$( mount | grep -c "${FMLIST_SCAN_RESULT_DIR}" )
if [ $MNTC -eq 0 ] && [ ${FMLIST_SCAN_MOUNT} -eq 1 ]; then
  mount "${FMLIST_SCAN_RESULT_DIR}"
  MNTC=$( mount | grep -c "${FMLIST_SCAN_RESULT_DIR}" )
  if [ $MNTC -eq 0 ]; then
    echo "Error: Device (USB memory stick) is not available on ${FMLIST_SCAN_RESULT_DIR} !"
    exit 10
  fi
fi

if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner" ]; then
  mkdir -p "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner"
fi


echo "" >"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/error.log"

if [ ${FMLIST_SCAN_MOUNT} -eq 1 ]; then
  FM=$( df -h -m ${FMLIST_SCAN_RESULT_DEV} | tail -n 1 | awk '{ print $4; }' )
  if [ $FM -le 5 ]; then
    echo "Error: not enough space on USB stick ${FMLIST_SCAN_RESULT_DEV} !"
    echo "Error: not enough space on USB stick ${FMLIST_SCAN_RESULT_DEV} !" >>"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/error.log"
    exit 10
  fi
fi

# create config folder
if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config" ]; then
  mkdir -p "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config"
fi

# copy/use new configuration - if exists
if [ $( ls -1 "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/" | wc -l ) -ne 0 ]; then

  # check, if there any new config file to apply?
  HAVE_NEW_CONF="0"
  if [ -f "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/wpa_supplicant.conf" ]; then HAVE_NEW_CONF="1" ; fi
  if [ -f "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/config" ]; then HAVE_NEW_CONF="1" ; fi
  if [ -f "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/dab_chanlist.txt" ]; then HAVE_NEW_CONF="1" ; fi
  if [ -f "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/dabscan.inc" ]; then HAVE_NEW_CONF="1" ; fi
  if [ -f "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/fmscan.inc" ]; then HAVE_NEW_CONF="1" ; fi
  if [ "${HAVE_NEW_CONF}" = "1" ]; then
    LPIE_BIN="$(which lpie 2>/dev/null)"
    if [ ! -z "${LPIE_BIN}" ]; then
      R="$( sudo lpie status 2>&1 | grep "filesystem mode:" | grep -c "overlayfs" )"
      if [ $R -ne 0 ]; then
        # extra reboot (into ro/overlay mode) after application of new config files
        touch "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/reboot"
        echo "found new config whilst lpie in overlay mode. going for reboot-rw .." >>"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/reboots.log"
        sync
        sleep 5
        sudo lpie reboot-rw
        exit 0
      fi
    fi
  fi

  # append to /etc/wpa_supplicant/wpa_supplicant.conf
  if [ -f "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/wpa_supplicant.conf" ]; then
    dos2unix "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/wpa_supplicant.conf"
    sudo bash -c "cat ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/wpa_supplicant.conf >>/etc/wpa_supplicant/wpa_supplicant.conf"
    if [ -s ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/wpa_supplicant.conf ] ; then
      touch "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/reboot"
    fi
  fi
  # replace config files
  if [ -f "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/config" ]; then
    dos2unix "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/config"
    cp "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/config" "$HOME/.config/fmlist_scan/"
  fi
  if [ -f "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/dab_chanlist.txt" ]; then
    dos2unix "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/dab_chanlist.txt"
    cp "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/dab_chanlist.txt" "$HOME/.config/fmlist_scan/"
  fi
  if [ -f "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/dabscan.inc" ]; then
    dos2unix "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/dabscan.inc"
    cp "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/dabscan.inc" "$HOME/.config/fmlist_scan/"
  fi
  if [ -f "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/fmscan.inc" ]; then
    dos2unix "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/fmscan.inc"
    cp "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/fmscan.inc" "$HOME/.config/fmlist_scan/"
  fi

  if [ -d "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config_applied" ]; then
    rm -rf "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config_applied"
  fi

  mv "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config" "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config_applied"
  mkdir -p "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config"

  if [ "${HAVE_NEW_CONF}" = "1" ] && [ -f "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config_applied/reboot" ]; then
    # reboot (back into ro/overlay mode) after application of new config files
    echo "applied new config files. going for reboot for getting back into overlay mode .." >>"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/reboots.log"
    sync
    sleep 5
    sudo /sbin/reboot now
    exit 0
  fi

  # re-read config
  source $HOME/.config/fmlist_scan/config
fi

echo "# additional network config. fill in your SSID and passphrase and rename this file:" >"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/old_wpa_supplicant.conf"
echo "network={"            >>"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/old_wpa_supplicant.conf"
echo "  ssid=\"SSID\""      >>"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/old_wpa_supplicant.conf"
echo "  psk=\"passphrase\"" >>"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/old_wpa_supplicant.conf"
echo "}"                    >>"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/old_wpa_supplicant.conf"

cp "$HOME/.config/fmlist_scan/config"           "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/old_config"
cp "$HOME/.config/fmlist_scan/dab_chanlist.txt" "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/old_dab_chanlist.txt"
cp "$HOME/.config/fmlist_scan/dabscan.inc"      "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/old_dabscan.inc"
cp "$HOME/.config/fmlist_scan/fmscan.inc"       "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/old_fmscan.inc"


sync


if [ "$1" = "autostart" ] ; then
  if [ "${FMLIST_SCAN_GPS_ALL_TIME}" = "1" ]; then
    $HOME/bin/startGpsLoop.sh
  fi
  if [ ${FMLIST_SCAN_AUTOSTART} -eq 0 ]; then
    echo "autostart is deactivated in $HOME/.config/fmlist_scan/config"
    echo "autostart is deactivated in $HOME/.config/fmlist_scan/config" >>"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/error.log"
    exit 10
   fi
fi

echo "" >${FMLIST_SCAN_RAM_DIR}/LAST
rm -f ${FMLIST_SCAN_RAM_DIR}/scanLoopBgRunning

echo "starting screen session 'scanLoopBg' .."

screen -d -m -S scanLoopBg bash "$HOME/bin/scanLoop.sh"
sleep 2
SSESSION="$( screen -ls | grep scanLoopBg )"
if [ -z "$SSESSION" ]; then
  echo "Error starting screen session"
  echo "Error starting screen session" >>"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/error.log"
  exit 10
fi

