#!/bin/bash

if [ ! "$(whoami)" = "root" ]; then
  echo "$0 must be called as root or with sudo"
  exit 0
fi

source $HOME/.config/fmlist_scan/config

if [ ! "$HOME" = "/home/${FMLIST_SCAN_USER}" ]; then
  echo "error: call sudo with option '-E' to preserve users home directory!"
  exit 0
fi

echo "starting uninstall .."
echo "with HOME = ${HOME}"
echo "and  FMLIST_SCAN_USER = ${FMLIST_SCAN_USER}"

echo "removing entries from crontab .."
. uninstall_crontab.sh

# remove aliases
echo "removing entries from ~/.bash_aliases .."
ALIASEXPRA="$( echo -n "$(pwd)/.bash_aliases" |sed "s#/#\\\\/#g" )"
ALIASEXPRB="$( echo -n "/home/${FMLIST_SCAN_USER}/bash_aliases_fmlist_scanner" |sed "s#/#\\\\/#g" )"
sudo -u ${FMLIST_SCAN_USER} bash -c "sed -i '/${ALIASEXPRA}/d' /home/${FMLIST_SCAN_USER}/.bash_aliases"
sudo -u ${FMLIST_SCAN_USER} bash -c "sed -i '/${ALIASEXPRB}/d' /home/${FMLIST_SCAN_USER}/.bash_aliases"

# remove login status message
echo "removing lpie status message from ~/.bashrc .."
ALIASEXPR="$( echo -n "$(pwd)/lpie_status.sh" |sed "s#/#\\\\/#g" )"
sudo -u ${FMLIST_SCAN_USER} bash -c "sed -i '/${ALIASEXPR}/d' /home/${FMLIST_SCAN_USER}/.bashrc"

# remove gps scripts
echo "removing gps scripts from $HOME/bin .."
rm -f "$HOME/bin/get_gpstime.sh"
rm -f "$HOME/bin/gpstime.sh"

# remove scan scripts
echo "removing scan scripts from $HOME/bin .."
rm -f "$HOME/bin/checkBgScanLoop.sh"
rm -f "$HOME/bin/checkScanConfig.sh"
rm -f "$HOME/bin/monitorBgScanLoop.sh"
rm -f "$HOME/bin/statusBgScanLoop.sh"
rm -f "$HOME/bin/createFMoverview.py"
rm -f "$HOME/bin/scanFM.sh"
rm -f "$HOME/bin/scanDAB.sh"
rm -f "$HOME/bin/scanLoop.sh"
rm -f "$HOME/bin/startBgScanLoop.sh"
rm -f "$HOME/bin/stopBgScanLoop.sh"
rm -f "$HOME/bin/startGpsLoop.sh"
rm -f "$HOME/bin/stopGpsLoop.sh"
rm -f "$HOME/bin/waitScreenTermination.sh"
rm -f "$HOME/bin/scanToneFeedback.sh"
rm -f "$HOME/bin/pipwm.sh"
rm -f "$HOME/bin/saveScanResults.sh"
rm -f "$HOME/bin/rmScanResults.sh"
rm -f "$HOME/bin/concatScanResults.sh"
rm -f "$HOME/bin/prepareScanResultsForUpload.sh"
rm -f "$HOME/bin/uploadScanResults.sh"
rm -f "$HOME/bin/uploadScanFilesToDeveloper.sh"
rm -f "$HOME/bin/downloadScanFilesFromDeveloper.sh"
rm -f "$HOME/bin/anonTimeForPreparedResults.sh"
rm -f "$HOME/bin/redsea.json2csv.sh"
rm -f "$HOME/bin/scanTest.sh"
rm -f "$HOME/bin/recDAB.sh"
rm -f "$HOME/bin/recDABeti.sh"
rm -f "$HOME/bin/recDABaudio.sh"
rm -f "$HOME/bin/listenDAB.sh"
rm -f "$HOME/bin/recWFMchunk.sh"
rm -f "$HOME/bin/atx-knob.sh"
rm -f "$HOME/bin/listUSBdevices.sh"
rm -f "$HOME/bin/powerOff_rtl_by_serial.sh"
rm -f "$HOME/bin/powerOn_rtl_by_serial.sh"
rm -f "$HOME/bin/reset_rtl_by_serial.sh"
rm -f "$HOME/bin/resetScanDevice.sh"
rm -f "$HOME/bin/rmmod_rtl_dvb.sh"
rm -f "$HOME/bin/scanner_fix-uuid.sh"
rm -f "$HOME/bin/scanner_format_f2fs.sh"
rm -f "$HOME/bin/scanner_format_vfat.sh"
rm -f "$HOME/bin/scanner_sunrise_and_set.sh"
rm -f "$HOME/bin/scanner_mount_result_dir.sh.inc"
rm -f "$HOME/bin/get-adapter-info.py"
rm -f "$HOME/bin/scanner_auto_config.sh"
rm -f "$HOME/bin/scanner_reconfig_rc.sh"
rm -f "$HOME/bin/scanner_versions.sh"

rm -f "$HOME/bin/scanEvalDABens.sh"
rm -f "$HOME/bin/scanEvalDABensTii.sh"
rm -f "$HOME/bin/scanEvalDABprogs.sh"
rm -f "$HOME/bin/scanEvalFMcmpPI.sh"
rm -f "$HOME/bin/scanEvalFMcmpPS.sh"
rm -f "$HOME/bin/scanEval.inc"
rm -f "$HOME/bin/uniq_count.awk"

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

echo "removing webserver scripts from $HOME/bin .."
rm -f "$HOME/bin/scan-httpserver.py"
rm -f "$HOME/bin/scannerPrepareWifiConfig.sh"
rm -f "$HOME/bin/scannerFinalizeWifiConfig.sh"
rm -f "$HOME/bin/scannerResetWifiConfig.sh"
rm -f "$HOME/bin/scannerReconfigWifi.sh"

echo "removing scan-webserver.service .."
sudo systemctl stop scan-webserver.service
sudo systemctl disable scan-webserver.service
sudo rm /lib/systemd/system/scan-webserver.service


echo -e "\nuninstall built packages:"
echo -e "\nlibrtlsdr:"          ; (cd git/hayguen/build_librtlsdr          && sudo make uninstall )
echo -e "\ndab-cmdline_files:"  ; (cd git/hayguen/build_dab-cmdline_files  && sudo make uninstall )
echo -e "\ndab-cmdline_rtlsdr:" ; (cd git/hayguen/build_dab-cmdline_rtlsdr && sudo make uninstall )
echo -e "\neti-cmdline:"        ; (cd git/hayguen/build_eti-stuff_rtlsdr   && sudo make uninstall )
echo -e "\ncsdr:"               ; (cd git/simonyiszk/csdr       && sudo make uninstall )
echo -e "\nredsea:"             ; (cd git/windytan/redsea       && sudo make uninstall )
echo -e "\nlib liquid-dsp:"     ; (cd git/jgaeddert/liquid-dsp  && sudo make uninstall )
echo -e "\nkalibrate-rtl:"      ; (cd git/steve-m/kalibrate-rtl && sudo make uninstall )
# echo -e "\nlibcorrect:"     ; (cd git/quiet/libcorrect      && sudo make uninstall )


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

