This is a to-do-list and a collection of ideas for the FMLIST-Scanner

# Improvements and Ideas

## open

- [ ] make parallel scanning (TEF/RTLSDR) possible
- [ ] intelligent mobile scan for new signals (for example stay longer when captured for first time)
- [ ] think about removing the webserver password at all (as it is in local network anyway)
- [ ] GPS and TEF serial connection still to be tested in parallel (`/dev/ttyUSB0` conflict?)
- [ ] switch off unused components (HDMI, Bluetooth) in order to reduce power consumption and make this accessible thru Webserver
- [ ] check why `gpsd-client` is not installed
- [ ] add comments for suitable operating systems, Armbian not working due to sudo problems
- [ ] convert manual (PDF) to Markdown and translate it line by line to English (work still in progress).
- [ ] check if `scan_*_dab_gps.csv` is really needed (as always 0 bytes)

## in progress

- [ ] use a modern webserver UI (started, but not fully implemented)

## already done 

- [x] integration of TEF6686 through serial and WiFi connection, while DAB uses rtlsdr
- [x] AF now sorted
- [x] in monitor, show a history of logged frequencies and print PS/PI and Ensemble
- [x] detailled audio analysis for DAB audio streams (only when static )
- [x] install eti-cmdline as default
- [x] install webserver by default
- [x] print message when installation was successful or when it failed
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


Updated: July 2026
