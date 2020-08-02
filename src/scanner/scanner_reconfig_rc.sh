#!/bin/bash

export LC_ALL=C
source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_PATH}" ]; then
  echo "Error: FMLIST_SCAN_PATH ${FMLIST_SCAN_PATH} does not exist!"
  exit 1
fi

RCPORT="$1"
if [ -z "${RCPORT}" ] || [ "${RCPORT}" = "0" ]; then
  echo "Error: Expected port number > 0 as argument to this script"
  exit 2
fi

SIDEDOOR_CONF_LINE=$(grep "^OPTIONS=" /etc/default/sidedoor)
echo "current configuration: ${SIDEDOOR_CONF_LINE}"

N_PORT_MATCHES=$(echo "${SIDEDOOR_CONF_LINE}" |grep -c -- "-R ${RCPORT}:localhost:22")
# echo "N_PORT_MATCHES ${N_PORT_MATCHES}"

if [ "${N_PORT_MATCHES}" == "0" ]; then
  SVC_FILE_EXISTS=$(systemctl list-unit-files sidedoor.service |grep -c sidedoor.service)
  if [ "${SVC_FILE_EXISTS}" = "1" ]; then
    systemctl is-enabled -q sidedoor.service
    SVC_ENABLED="$?"
    if [ "${SVC_ENABLED}" = "0" ]; then
      systemctl is-active -q sidedoor.service
      SVC_ACTIVE="$?"
      if [ "${SVC_ACTIVE}" = "0" ]; then
        echo "sidedoor.service is already active"
      else
        echo "Error: sidedoor.service was not active!"
      fi
    else
      echo "Error: sidedoor.service was not enabled!"
    fi
  else
    echo "Error: sidedoor.service file not installed"
  fi

  echo "configured port and argument don't match. call reconfiguration .."
  pushd "${FMLIST_SCAN_PATH}/.."
    pwd
    echo sudo -E ./setup_sidedoor "${RCPORT}"
  popd

  echo "wait 5 seconds for establishment or error .."
  sleep 5

  SVC_FILE_EXISTS=$(systemctl list-unit-files sidedoor.service |grep -c sidedoor.service)
  if [ "${SVC_FILE_EXISTS}" = "1" ]; then
    systemctl is-enabled -q sidedoor.service
    SVC_ENABLED="$?"
    if [ "${SVC_ENABLED}" = "0" ]; then
      systemctl is-active -q sidedoor.service
      SVC_ACTIVE="$?"

      echo "Restarting sidedoor.service"
      sudo systemctl restart sidedoor.service
    else
      echo "Error: sidedoor.service is not enabled!"
    fi
  else
    echo "Error: sidedoor.service file not installed"
  fi
fi

