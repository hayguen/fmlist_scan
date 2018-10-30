#!/bin/bash

if [ ! "$(whoami)" = "root" ]; then
  echo "$0 must be called as root or with sudo"
  exit 0
fi

source $HOME/.config/fmlist_scan/config

if [ ! "$HOME" = "/home/${FMLIST_SCAN_USER}" ]; then
  echo "error: call sudo with option '-E' to preserver users home directory!"
  exit 0
fi

echo "starting uninstall .."
echo "with HOME = ${HOME}"
echo "and  FMLIST_SCAN_USER = ${FMLIST_SCAN_USER}"

echo "removing entries from crontab .."
. uninstall_crontab.sh

# remove aliases
echo "removing entries from ~/.bash_aliases .."
ALIASEXPR="$( echo -n "$(pwd)/.bash_aliases" |sed "s#/#\\\\/#g" )"
sudo -u ${FMLIST_SCAN_USER} bash -c "sed -i '/${ALIASEXPR}/d' /home/${FMLIST_SCAN_USER}/.bash_aliases"

# remove gps scripts
echo "removing gps scripts from $HOME/bin .."
rm -f "$HOME/bin/get_gpstime.sh"
rm -f "$HOME/bin/gpstime.sh"

# remove scan scripts
echo "removing scan scripts from $HOME/bin .."
rm -f "$HOME/bin/checkBgScanLoop.sh"
rm -f "$HOME/bin/scanFM.sh"
rm -f "$HOME/bin/scanDAB.sh"
rm -f "$HOME/bin/scanLoop.sh"
rm -f "$HOME/bin/startBgScanLoop.sh"
rm -f "$HOME/bin/stopBgScanLoop.sh"
rm -f "$HOME/bin/scanToneFeedback.sh"
rm -f "$HOME/bin/saveScanResults.sh"
rm -f "$HOME/bin/concatScanResults.sh"
rm -f "$HOME/bin/prepareScanResultsForUpload.sh"
rm -f "$HOME/bin/uploadScanResults.sh"
rm -f "$HOME/bin/redsea.json2csv.sh"
rm -f "$HOME/bin/scanTest.sh"
rm -f "$HOME/bin/recDAB.sh"
rm -f "$HOME/bin/recWFMchunk.sh"

echo "removing calibration script from $HOME/bin .."
rm -f "$HOME/bin/kal.sh"

echo "removing scan binaries from $HOME/bin .."
rm -f "$HOME/bin/checkSpectrumForCarrier"
rm -f "$HOME/bin/prescanDAB"
rm -f "$HOME/bin/pipwm"

echo "removing rpi3b led scripts from $HOME/bin .."
rm -f "$HOME/bin/rpi3b_led_blinkRed.sh"
rm -f "$HOME/bin/rpi3b_led_init.sh"
rm -f "$HOME/bin/rpi3b_led_next.sh"


echo ""
echo "keeping gpio-input.service. deactivate with:"
echo "  sudo systemctl stop gpio-input.service"
echo "  sudo systemctl disable gpio-input.service"
echo "  sudo rm /lib/systemd/system/gpio-input.service"
echo ""
echo "keeping gpsd. deactivate with:"
echo "  sudo systemctl stop gpsd.socket"
echo "  sudo systemctl disable gpsd.socket"
echo ""
echo "keeping config files in $HOME/.config/fmlist_scan/"
echo "  backup/save somewhere:"
echo "  mkdir ~/backup_fmlist_scan_config"
echo "  cp -r \$HOME/.config/fmlist_scan  ~/backup_fmlist_scan_config/"
echo ""
echo "verify crontab with:"
echo "  crontab -e"
echo ""
echo "keeping /etc/fstab. check/fix with editor!:"
echo "  sudo mcedit /etc/fstab"
echo ""
echo "now reboot:"
echo "  sudo reboot now"
echo ""

