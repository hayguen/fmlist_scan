#!/bin/bash

sudo wpa_cli -i wlan0 reconfigure
if [ $? -eq 0 ]; then
  echo "Success with wpa_cli -i wlan0 reconfigure."
  exit 0
fi

echo "Failed to reconfigure wlan0 with wpa_cli."
echo "Restarting dhcpcd with systemctl."
sudo systemctl restart dhcpcd
sleep 2

sudo wpa_cli -i wlan0 reconfigure
if [ $? -eq 0 ]; then
  echo "Success with wpa_cli -i wlan0 reconfigure at 2nd try."
  exit 0
fi

echo "Failed to reconfigure wlan0 with wpa_cli at 2nd try."
echo "Restarting dhcpcd with systemctl."
sudo systemctl restart dhcpcd
sleep 2

sudo wpa_cli -i wlan0 reconfigure
if [ $? -eq 0 ]; then
  echo "Success with wpa_cli -i wlan0 reconfigure at 3rd try."
  exit 0
fi

echo "Failed to reconfigure wlan0 with wpa_cli at 3rd try. Giving Up!"
