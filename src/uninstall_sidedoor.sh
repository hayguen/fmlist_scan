#!/bin/bash

if [ ! "$(whoami)" = "root" ]; then
  echo "$0 must be called with sudo -E ./uninstall_sidedoor.sh"
  exit 0
fi

source $HOME/.config/fmlist_scan/config

if [ -z "${FMLIST_SCAN_USER}" ]; then
  echo "error: missing or invalid config file '$HOME/.config/fmlist_scan/config'."
  echo "   variable FMLIST_SCAN_USER is empty."
  exit 0
fi

if [ ! "$HOME" = "/home/${FMLIST_SCAN_USER}" ]; then
  echo "error: call sudo with option '-E' to preserve users home directory!"
  echo "  call: sudo -E ./uninstall_sidedoor.sh"
  exit 0
fi

# read configuration
. sidedoor_config

systemctl stop sidedoor.service
systemctl disable sidedoor.service
rm -f /usr/lib/systemd/system/sidedoor.service
systemctl daemon-reload
systemctl reset-failed

rm -rf /etc/sidedoor
rm -rf /var/lib/sidedoor

if [ ! -z "${RSSH_USER}" ]; then
  echo "checking for user ${RSSH_USER}"
  id -u ${RSSH_USER}
  RETUSERCHECK=$?
  if [ "${RETUSERCHECK}" = "0" ]; then
    echo "user '${RSSH_USER}' exists. removing .."
    deluser --force --remove-home "${RSSH_USER}"
  fi
  rm -f /etc/sudoers.d/010_${RSSH_USER}_nopasswd
else
  echo "No RSSH_USER configured"
fi
