#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

source /home/${FMLIST_SCAN_USER}/bin/scanner_mount_result_dir.sh.inc

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

  # append to /etc/wpa_supplicant/wpa_supplicant.conf
  if [ -f "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/wpa_supplicant.conf" ]; then
    dos2unix "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/wpa_supplicant.conf"
    sudo bash -c "cat ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config/wpa_supplicant.conf >>/etc/wpa_supplicant/wpa_supplicant.conf"

    # raspi_config and wpa_supplicant require global configuration
    # create if not existing
    mkdir /dev/shm/wpa_supplicant
    chmod 700 /dev/shm/wpa_supplicant
    touch /dev/shm/wpa_supplicant/wpa_supplicant_.conf
    sudo cp /etc/wpa_supplicant/wpa_supplicant.conf /dev/shm/wpa_supplicant/wpa_supplicant_.conf
    chown ${whoami}:${whoami} /dev/shm/wpa_supplicant/wpa_supplicant_.conf

    NCTRLIFC=$( grep -c "^ctrl_interface=" /dev/shm/wpa_supplicant/wpa_supplicant_.conf )
    NUPDATE=$(  grep -c "^update_config="  /dev/shm/wpa_supplicant/wpa_supplicant_.conf )
    NCOUNTRY=$( grep -c "^country="        /dev/shm/wpa_supplicant/wpa_supplicant_.conf )

    CCTRLIFC=$( grep "^ctrl_interface=" /dev/shm/wpa_supplicant/wpa_supplicant_.conf |tail -n 1 )
    CUPDATE=$(  grep "^update_config="  /dev/shm/wpa_supplicant/wpa_supplicant_.conf |tail -n 1 )
    CCOUNTRY=$( grep "^country="        /dev/shm/wpa_supplicant/wpa_supplicant_.conf |tail -n 1 )

    if [ "${NCTRLIFC}" = "0" ]; then
      CCTRLIFC="ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev"
    fi
    if [ "${NUPDATE}" = "0" ]; then
      CUPDATE="update_config=1"
    fi
    if [ "${NCOUNTRY}" = "0" ]; then
      CCOUNTRY="country=DE"
    fi

    cat /dev/shm/wpa_supplicant/wpa_supplicant_.conf \
      | grep -v "^ctrl_interface=" \
      | grep -v "^update_config=" \
      | grep -v "^country=" \
      | sed "1i${CCTRLIFC}" \
      | sed "2i${CUPDATE}" \
      | sed "3i${CCOUNTRY}" >/dev/shm/wpa_supplicant/wpa_supplicant.conf

    cp /dev/shm/wpa_supplicant/wpa_supplicant.conf ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/config_wpa_supplicant.conf
    sudo cp /dev/shm/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf

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


# increase usb buffers - looks new librtlsdr requires this
echo 0 | sudo tee /sys/module/usbcore/parameters/usbfs_memory_mb


if [ "$1" = "autostart" ] ; then
  DTF="$(date -u "+%Y-%m-%dT%T.%N Z")"
  echo "${DTF}: executing startBgScanLoop.sh with 'autostart' option" >>"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/reboots.log"

  if [ "${FMLIST_SCAN_GPS_ALL_TIME}" = "1" ]; then
    $HOME/bin/startGpsLoop.sh
  fi
  if [ ${FMLIST_SCAN_AUTOSTART} -eq 0 ]; then
    echo "${DTF}: autostart is deactivated in $HOME/.config/fmlist_scan/config"
    echo "${DTF}: autostart is deactivated in $HOME/.config/fmlist_scan/config" >>"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/error.log"
    echo "${DTF}: autostart is deactivated in $HOME/.config/fmlist_scan/config" >>"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/reboots.log"
    exit 10
   fi
fi

for f in $(echo "config" "dab_chanlist.txt" "dabscan.inc" "fmscan.inc" ) ; do
  cp "$HOME/.config/fmlist_scan/${f}"      "${FMLIST_SCAN_RAM_DIR}/"
  dos2unix "${FMLIST_SCAN_RAM_DIR}/${f}"     >/dev/null 2>/dev/null
  cmp "$HOME/.config/fmlist_scan/${f}"     "${FMLIST_SCAN_RAM_DIR}/${f}"  >/dev/null 2>/dev/null
  CMPRESULT=$?
  if [ ! $CMPRESULT -eq 0 ]; then
    cp "${FMLIST_SCAN_RAM_DIR}/${f}"       "$HOME/.config/fmlist_scan/"
  fi
  rm "${FMLIST_SCAN_RAM_DIR}/${f}"
done

if [ "$1" = "autostart" ] && [ "$2" = "upload" ] ; then
  uploadScanResults.sh
fi

echo "" >${FMLIST_SCAN_RAM_DIR}/LAST
rm -f ${FMLIST_SCAN_RAM_DIR}/stopScanLoop
# signal desired state - not the current one
echo "1" >${FMLIST_SCAN_RAM_DIR}/scanLoopBgRunning

echo "starting screen session 'scanLoopBg' .."

screen -d -m -S scanLoopBg bash "$HOME/bin/scanLoop.sh"
sleep 2
SSESSION="$( screen -ls | grep scanLoopBg )"
if [ -z "$SSESSION" ]; then
  echo "Error starting screen session"
  echo "Error starting screen session" >>"${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/error.log"
  exit 10
fi

