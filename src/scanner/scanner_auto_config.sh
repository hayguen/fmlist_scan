#!/bin/bash

if [ -z "${FMLIST_SCAN_RAM_DIR}" ]; then
  source $HOME/.config/fmlist_scan/config
  if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
    mkdir -p "${FMLIST_SCAN_RAM_DIR}"
  fi
fi

export LC_ALL=C
cd "${FMLIST_SCAN_RAM_DIR}"

if [ ! "${FMLIST_SCAN_AUTO_IP_INFO}" = "1" ]; then
  echo "FMLIST_SCAN_AUTO_IP_INFO is not active"
  exit 0
fi

PREV_URL="$(cat "${FMLIST_SCAN_RAM_DIR}/LAST_CONFIG_URL")"
URL=$(get-adapter-info.py eth0 wlan0 |grep "^URL:" |sed 's/^URL://g' )
echo "$URL"
if [ -z "${URL}" ]; then
  echo "Error: could not retrieve URL / results of get-adapter-info.py"
  exit 10
fi

if [ "${PREV_URL}" = "${URL}" ]; then
  echo "MAC and IPs are still same to previous request"
  echo "  see ${FMLIST_SCAN_RAM_DIR}/LAST_CONFIG_URL"
  exit 0
else
  echo "MAC and IPs differ to previous request"
fi

echo -n "${URL}" >"${FMLIST_SCAN_RAM_DIR}/LAST_CONFIG_URL"


FIELD=$( echo "$URL" | cut -d '&' -f 1 | cut -d '?' -f 2 )
FIELD_NAME=$( echo "${FIELD}" | cut -d '=' -f 1)
FIELD_VALUE=$( echo "${FIELD}" | cut -d '=' -f 2)
echo "FIELD_NAME:  ${FIELD_NAME}"
echo "FIELD_VALUE: ${FIELD_VALUE}"
if [ "${FIELD_NAME}" = "mac" ]; then
  echo "current MAC is ${FIELD_VALUE}"
else
  echo "Error: FIELD_NAME should be 'mac'"
fi
MAC_UCASE=$(echo -n "${FIELD_VALUE}" |tr [a-z] [A-Z])

# upload new local IPs
curl "$URL" >auto_config.txt
echo "$(cat auto_config.txt)"

if [ ! "${FMLIST_SCAN_AUTO_CONFIG}" = "1" ]; then
  echo "FMLIST_SCAN_AUTO_CONFIG is not active"
  exit 0
fi

RESULT_MATCH="0"
echo -e "\nevaluate found field"
FIELD=$(cut -d ';' -f 1 auto_config.txt)
if [ ! -z "${FIELD}" ]; then
  FIELD_NAME=$( echo "${FIELD}" | cut -d ':' -f 1)
  FIELD_VALUE=$( echo "${FIELD}" | cut -d ':' -f 2)
  echo "FIELD_NAME:  ${FIELD_NAME}"
  echo "FIELD_VALUE: ${FIELD_VALUE}"
  if [ "${FIELD_NAME}" = "found" ]; then
    if [ ! "${FIELD_VALUE}" = "true" ]; then
      echo "Error: RETURN does NOT match!"
    else
      echo "RETURN_MATCHES"
      RESULT_MATCH="1"
    fi
  else
    echo "Error: FIELD_NAME should be 'found'"
  fi
fi



if [ "${RESULT_MATCH}" = "1" ]; then

  echo -e "\nevaluate MAC field"
  FIELD=$(cut -d ';' -f 2 auto_config.txt)
  if [ ! -z "${FIELD}" ]; then
    FIELD_NAME=$( echo "${FIELD}" | cut -d ':' -f 1)
    FIELD_VALUE=$( echo "${FIELD}" | cut -d ':' -f 2)
    echo "FIELD_NAME:  ${FIELD_NAME}"
    echo "FIELD_VALUE: ${FIELD_VALUE}"
    if [ "${FIELD_NAME}" = "macaddr" ]; then
      if [ ! "${FIELD_VALUE}" = "${MAC_UCASE}" ]; then
        echo "Error: MAC mismatch from request and response!"
      else
        echo "MAC of request and response do MATCH"
      fi
    else
      echo "Error: FIELD_NAME should be 'macaddr'"
    fi
  fi

  echo -e "\nevaluate remote control field"
  FIELD=$(cut -d ';' -f 4 auto_config.txt)
  if [ ! -z "${FIELD}" ]; then
    FIELD_NAME=$( echo "${FIELD}" | cut -d ':' -f 1)
    FIELD_VALUE=$( echo "${FIELD}" | cut -d ':' -f 2)
    echo "FIELD_NAME:  ${FIELD_NAME}"
    echo "FIELD_VALUE: ${FIELD_VALUE}"
    if [ "${FIELD_NAME}" = "rcport" ]; then
      if [ ! -z "${FIELD_VALUE}" ]; then
        echo "need check/reconfig of remote control port"
        #scanner_reconfig_rc.sh "${FIELD_VALUE}"
      fi
    else
      echo "Error: FIELD_NAME should be 'rcport'"
    fi
  fi

  echo -e "\nevaluate hostname field"
  CURR_HOSTNAME=$(hostname)
  FIELD=$(cut -d ';' -f 5 auto_config.txt)
  if [ ! -z "${FIELD}" ]; then
    FIELD_NAME=$( echo "${FIELD}" | cut -d ':' -f 1)
    FIELD_VALUE=$( echo "${FIELD}" | cut -d ':' -f 2)
    echo "FIELD_NAME:  ${FIELD_NAME}"
    echo "FIELD_VALUE: ${FIELD_VALUE}"
    if [ "${FIELD_NAME}" = "hostname" ]; then
      if [ ! -z "${FIELD_VALUE}" ]; then
        if [ "${FIELD_VALUE}" = "${CURR_HOSTNAME}" ]; then
          echo "hostname does MATCH"
        else
          echo "hostname does DIFFER: change ${CURR_HOSTNAME} to ${FIELD_VALUE}"
          # "${FIELD_VALUE}"
        fi
      fi
    else
      echo "Error: FIELD_NAME should be 'hostname'"
    fi
  fi

  echo -e "\nevaluate upload comment field"
  FIELD=$(cut -d ';' -f 6 auto_config.txt)
  if [ ! -z "${FIELD}" ]; then
    FIELD_NAME=$( echo "${FIELD}" | cut -d ':' -f 1)
    FIELD_VALUE=$( echo "${FIELD}" | cut -d ':' -f 2)
    echo "FIELD_NAME:  ${FIELD_NAME}"
    echo "FIELD_VALUE: ${FIELD_VALUE}"
    if [ "${FIELD_NAME}" = "nupcomment" ]; then
      if [ ! -z "${FIELD_VALUE}" ]; then
        echo "need to check/change upload comment"
      fi
    else
      echo "Error: FIELD_NAME should be 'nupcomment'"
    fi
  fi

  echo -e "\nevaluate upload permision field"
  FIELD=$(cut -d ';' -f 7 auto_config.txt)
  if [ ! -z "${FIELD}" ]; then
    FIELD_NAME=$( echo "${FIELD}" | cut -d ':' -f 1)
    FIELD_VALUE=$( echo "${FIELD}" | cut -d ':' -f 2)
    echo "FIELD_NAME:  ${FIELD_NAME}"
    echo "FIELD_VALUE: ${FIELD_VALUE}"
    if [ "${FIELD_NAME}" = "nuppermission" ]; then
      if [ ! -z "${FIELD_VALUE}" ]; then
        echo "need to check/change upload permission"
      fi
    else
      echo "Error: FIELD_NAME should be 'nuppermission'"
    fi
  fi

  echo -e "\nevaluate upload restrict field"
  FIELD=$(cut -d ';' -f 8 auto_config.txt)
  if [ ! -z "${FIELD}" ]; then
    FIELD_NAME=$( echo "${FIELD}" | cut -d ':' -f 1)
    FIELD_VALUE=$( echo "${FIELD}" | cut -d ':' -f 2)
    echo "FIELD_NAME:  ${FIELD_NAME}"
    echo "FIELD_VALUE: ${FIELD_VALUE}"
    if [ "${FIELD_NAME}" = "nuprestrict" ]; then
      if [ ! -z "${FIELD_VALUE}" ]; then
        echo "need to check/change upload restriction"
      fi
    else
      echo "Error: FIELD_NAME should be 'nuprestrict'"
    fi
  fi

  echo -e "\nevaluate upload position field"
  FIELD=$(cut -d ';' -f 9 auto_config.txt)
  if [ ! -z "${FIELD}" ]; then
    FIELD_NAME=$( echo "${FIELD}" | cut -d ':' -f 1)
    FIELD_VALUE=$( echo "${FIELD}" | cut -d ':' -f 2)
    echo "FIELD_NAME:  ${FIELD_NAME}"
    echo "FIELD_VALUE: ${FIELD_VALUE}"
    if [ "${FIELD_NAME}" = "nupposition" ]; then
      if [ ! -z "${FIELD_VALUE}" ]; then
        echo "need to check/change upload position"
      fi
    else
      echo "Error: FIELD_NAME should be 'nupposition'"
    fi
  fi

  echo -e "\nevaluate config password field"
  FIELD=$(cut -d ';' -f 10 auto_config.txt)
  if [ ! -z "${FIELD}" ]; then
    FIELD_NAME=$( echo "${FIELD}" | cut -d ':' -f 1)
    FIELD_VALUE=$( echo "${FIELD}" | cut -d ':' -f 2)
    echo "FIELD_NAME:  ${FIELD_NAME}"
    echo "FIELD_VALUE: ${FIELD_VALUE}"
    if [ "${FIELD_NAME}" = "configpw" ]; then
      if [ ! -z "${FIELD_VALUE}" ]; then
        echo "need to check/change config password"
        echo "$(echo "${FIELD_VALUE}" |xxd -r -p -)"
      fi
    else
      echo "Error: FIELD_NAME should be 'configpw'"
    fi
  fi


fi

