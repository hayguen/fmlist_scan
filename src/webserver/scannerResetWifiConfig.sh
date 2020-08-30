#!/bin/bash

FINALNAME="$1"
if [ -z "${FINALNAME}" ]; then
  FINALNAME="wpa_supplicant.conf"
fi
FINALPATH="/dev/shm/wpa_supplicant/${FINALNAME}"
PREPFILEPATH="${FINALPATH}.tmp"

# raspi_config and wpa_supplicant require global configuration
# create if not existing
mkdir /dev/shm/wpa_supplicant &>/dev/null
chmod 700 /dev/shm/wpa_supplicant
rm -f "${PREPFILEPATH}"
sudo cp /etc/wpa_supplicant/wpa_supplicant.conf "${PREPFILEPATH}"
sudo chown "$(whoami):$(whoami)" "${PREPFILEPATH}"
dos2unix "${PREPFILEPATH}"

NCTRLIFC=$( grep -c "^ctrl_interface=" "${PREPFILEPATH}" )
NUPDATE=$(  grep -c "^update_config="  "${PREPFILEPATH}" )
NCOUNTRY=$( grep -c "^country="        "${PREPFILEPATH}" )

CCTRLIFC=$( grep "^ctrl_interface=" "${PREPFILEPATH}" |tail -n 1 )
CUPDATE=$(  grep "^update_config="  "${PREPFILEPATH}" |tail -n 1 )
CCOUNTRY=$( grep "^country="        "${PREPFILEPATH}" |tail -n 1 )

if [ "${NCTRLIFC}" = "0" ]; then
  CCTRLIFC="ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev"
fi
if [ "${NUPDATE}" = "0" ]; then
  CUPDATE="update_config=1"
fi
if [ "${NCOUNTRY}" = "0" ]; then
  CCOUNTRY="country=DE"
fi

# looks, sed dislikes when having to insert non existent line numbers
while [ $(cat "${PREPFILEPATH}" | wc -l) -lt 4 ]; do
  echo "" >>"${PREPFILEPATH}"
done

cat "${PREPFILEPATH}" \
  | grep -v "^ctrl_interface=" \
  | grep -v "^update_config=" \
  | grep -v "^country=" \
  | sed "1i${CCTRLIFC}" \
  | sed "2i${CUPDATE}" \
  | sed "3i${CCOUNTRY}" \
  | sed '/^$/d' \
  | head -n 3 >"${FINALPATH}"

sudo cp /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant_old_bak.conf
sudo install -m 660 -o root -g root "${FINALPATH}" /etc/wpa_supplicant/wpa_supplicant.conf

echo "/etc/wpa_supplicant/wpa_supplicant.conf :"
sudo cat --number "/etc/wpa_supplicant/wpa_supplicant.conf"
echo ""
