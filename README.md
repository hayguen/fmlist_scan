# fmlist_scan

## General information

This is an FM (87.5-108 MHz) and DAB (Digital Audio Broadcasting) scanner for collecting automated logs on headless systems for later upload to FMLIST, including GPS tracking for mobile logs, RDS collection, DAB TII codes and DAB ensemble details, see URDS section at https://www.fmlist.org/ (login required).

The scanner mainly runs on Raspberry Pi 3B+ and 4B with RaspberryPi OS. Main parts also run on other Debian based Linux OS'es, requiring minor configuration.

The project was initially presented at the VHF meeting 2018: see https://ukw-tagung.org/

## Features

- automated logging of FM stations (with or without RDS)
- automated logging of DAB ensembles (including TII transmitter identification codes and detailed information about bitrates, protection levels and lables)
- ssh access via Internet (if configured)
- possibility of remote access for maintainers (if configured, only on demand) 
- record DAB muxes (raw file and eti file)
- record FM audio
- log files are stored on a USB stick
- webserver (on local networks) with configuration
- GPS integration (for position and actual time)
- works headless, both with and without graphical user interface (GUI)

## Further information (in German)

- script: https://codingspirit.de/Linux-ist-sexy-Freiheit-Skript.pdf
- slides: https://codingspirit.de/Linux-ist-sexy-Freiheit-Folien.pdf
- video of the presentation: https://www.ukwtv.de/cms/ukw-tv-arbeitskreis/aktivitaeten/744-vortraege-auf-der-ukw-tagung-2018.html
- step-by-step setup guide (work-in-progress): https://codingspirit.de/fmlist_scan_Step-by-Step.pdf

## Further information (in English)

Mailing List, Wiki, Translation of step-by-step setup guide and more: https://groups.io/g/fmlist-scanner

