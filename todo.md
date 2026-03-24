This is a to-do-list and a collection of ideas for the FMLIST-Scanner

# Improvements and Ideas

## open

- [ ] install webserver by default
- [ ] print message when installation was successful
- [ ] show voltage in monitorBgScanLoop
- [ ] switch off unused components (HDMI, Bluetooth) in order to reduce power consumption and make this accessible thru Webserver
- [ ] use a modern webserver UI
- [ ] install `net-tools` for `ifconfig` during installation
- [ ] check why gpsd is not installed
- [ ] detect bug and fix build directory for dab-cmdline in CMakeFiles

## already done 

- [x] RDSSpy time stamp added
- [x] improved output during installation and in scanTests
- [x] hint for sidedoor-scanner range added

# Bugs

## open

- [ ] scanTest 5 does not work
- [ ] gpsd checks return authentification error (but installation is not affected), `sudo scons` does not solve it
- [ ] updates might distroy GUI (Raspberry general)

## already done

- [x] fix csdr for version 0.19 and develop branch
- [x] Debian 13 (trixie) changed packages
- [x] fix redsea installation for RPI3B, will not crash

Updated: November 2025
