This is a to-do-list and a collection of ideas for the FMLIST-Scanner

# Improvements and Ideas

## open

- [ ] install webserver by default
- [ ] print message when installation was successful or when it failed
- [ ] switch off unused components (HDMI, Bluetooth) in order to reduce power consumption and make this accessible thru Webserver
- [ ] use a modern webserver UI
- [ ] check why `gpsd-client` is not installed
- [ ] install eti-cmdline as default
- [ ] add comments for suitable operating systems, Armbian not working due to sudo problems
- [ ] convert manual (PDF) to Markdown and translate it line by line to English (work still in progress).


## already done 

- [x] RDSSpy time stamp added
- [x] improved output during installation and in scanTests
- [x] hint for sidedoor-scanner range added
- [x] install dablin as additional package
- [x] install `net-tools` for `ifconfig` during installation
- [x] show voltage in monitorBgScanLoop (well, not done, but undervoltage will be shown)
- [x] RDS PS export underscores (`_`) instead of spaces
- [x] uninstall redsea is no more possible
- [x] found a way to skip 6144 bytes in eti and (!) display the console output anyway

# Bugs

## open

- [ ] updates might distroy GUI (Raspberry in general)
- [ ] detect bug and fix build directory for dab-cmdline in CMakeFiles
- [ ] `*.so` ist kein symbolischer Link


## already done

- [x] fix csdr for version 0.19 and develop branch
- [x] Debian 13 (trixie) changed packages
- [x] fix redsea installation for RPI3B, will not crash
- [x] gpsd checks return authentification error (but installation is not affected), `sudo scons` does not solve it, this has not be solved, but I have not seen it during the last installations
- [x] scanTest 5 does not work, seems scanTest 4 prepares the file, but the spectrum of test.raw looks strange


Updated: March 2026
