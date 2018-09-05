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
sudo -u ${FMLIST_SCAN_USER} bash -c "sed -i '#$(pwd)/.bash_aliases#d' /home/${FMLIST_SCAN_USER}/.bash_aliases"

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
rm -f "$HOME/bin/saveScanResults.sh"

echo "removing calibration script from $HOME/bin .."
rm -f "$HOME/bin/kal.sh"

echo "removing scan binaries from $HOME/bin .."
rm -f "$HOME/bin/checkSpectrumForCarrier"
rm -f "$HOME/bin/prescanDAB"

echo "removing rpi3b led scripts from $HOME/bin .."
rm -f "$HOME/bin/rpi3b_led_blinkRed.sh"
rm -f "$HOME/bin/rpi3b_led_init.sh"
rm -f "$HOME/bin/rpi3b_led_next.sh"
rm -f "$HOME/bin/rpi3b_led_play.sh"


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

