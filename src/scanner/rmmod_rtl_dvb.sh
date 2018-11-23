#!/bin/bash

#lsmod |egrep "dvb_|rtl2832|i2c_mux"

echo -e "\nsudo rmmod dvb_usb_rtl28xxu .."
sudo rmmod dvb_usb_rtl28xxu
#lsmod |egrep "dvb_|rtl2832|i2c_mux"

echo -e "\nsudo rmmod rtl2832 .."
sudo rmmod rtl2832
#lsmod |egrep "dvb_|rtl2832|i2c_mux"

echo -e "\nsudo rmmod dvb_usb_v2 .."
sudo rmmod dvb_usb_v2
#lsmod |egrep "dvb_|rtl2832|i2c_mux"

echo -e "\nsudo rmmod dvb_core .."
sudo rmmod dvb_core
#lsmod |egrep "dvb_|rtl2832|i2c_mux"

