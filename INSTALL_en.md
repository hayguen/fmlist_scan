# Setting up and running FMLIST_Scan on a Raspberry Pi 3B+, 3B or 4B

Für die deutschsprachige Version siehe [Installationsanweisung auf Deutsch](INSTALL_de.md)

## Author: 
Hayati Aygün (E-Mail: <h_ayguen@web.de>, ported to Markdown by Andreas Mikula (E-Mail: <andimik@yahoo.de>))

## GPG Fingerprint:	
`558E C9EF 3EAB 05E8 76AF 61DC D44C 9772 6FA1 CC0B`

## Table of Contents

- [1 Introduction](#section-1)
- [2 Requirements](#section-2)
- [3 Setup](#section-3)
    - [3.1 Preparing the Micro SD Card](#section-3-1)
    - [3.2 Setting up the Raspberry Pi OS system](#section-3-2)
        - [3.2.1 General](#section-3-2-1)
        - [3.2.2 Setup using a prepared FMLIST_SCAN image](#section-3-2-2)
        - [3.2.3 Setting up the Raspberry Pi OS image](#section-3-2-3)
- [4 Setting up the scanner](#section-4)
    - [4.1 Installing the scanner](#section-4-1)
    - [4.2 Configuring and Automatically Activating the Scanner](#section-4-2)
        - [4.2.1 TEF6686 and detailed DAB analysis](#section-4-2-1)
        - [4.2.2 Webserver](#section-4-2-2)
        - [4.2.3 SideDoor remote access](#section-4-2-3)
    - [4.3 Connecting ATX Buttons, LEDs, and Beepers](#section-4-3)
        - [4.3.1 CPU Fan Connection](#section-4-3-1)
        - [4.3.2 Piezo Beeper Connection](#section-4-3-2)
        - [4.3.3 ATX Button and LED Connection](#section-4-3-3)
- [5 Operating the Scanner](#section-5)
    - [5.1 Login / IP Address](#section-5-1)
        - [5.1.1 IP Address](#section-5-1-1)
        - [5.1.2 Operating Software for PC](#section-5-1-2)
        - [5.1.3 Software for Android Smartphones](#section-5-1-3)
    - [5.2 Adjusting the Configuration / Additional Wi-Fi](#section-5-2)
    - [5.3 Status Messages](#section-5-3)
    - [5.4 ATX Buttons](#section-5-4)
    - [5.5 At the Command Line](#section-5-5)
    - [5.6 Results](#section-5-6)
        - [5.6.1 Preparation and Upload](#section-5-6-1)
        - [5.6.2 Online Analysis](#section-5-6-2)
        - [5.6.3 Manual Analysis](#section-5-6-3)
    - [5.7 Recordings and Upload](#section-5-7)
    - [5.8 Problems and Possible Solutions](#section-5-8)

<a id="section-1"></a>
# 1 Introduction

**FMLIST_Scan**, hereinafter referred to as the "Scanner," was initiated by **Günter Lorenz**. The scanner is intended to collect station information for the FMLIST (https://www.fmlist.org/, station database of the UKW/TV-Arbeitskreis e.V.). The project was first presented on September 8, 2018, at the FM Conference in Weinheim (see https://ukw-tagung.org/).

The manuscript is available at https://codingspirit.de/Linux-ist-sexy-Freiheit-Skript.pdf, and the slides at https://codingspirit.de/Linux-ist-sexy-Freiheit-Folien.pdf

The manuscript and slides will be updated as needed, so the most recent version should always be accessed via the links above. The current source code is also available: https://github.com/hayguen/fmlist_scan

<a id="section-2"></a>
# 2 Requirements

The instructions require the following:

1. Raspberry Pi 3B+ including a suitable power supply (Note: a Pi 3B also works, but you'll need to perform the setup yourself for a Pi 4)
2. 16 GB micro SD card
3. USB flash drive
4. Temporary equipment, if needed: USB keyboard
5. Temporary equipment, if needed: display and, if necessary, an adapter for the Raspberry Pi's HDMI port
6. Temporary equipment, if needed: PC or notebook, micro SD reader, or adapter for a micro SD card
7. Wi-Fi or Ethernet cable to a router with internet access
8. RTL-SDR with an RTL2832 chip and an R820T or R820T2 tuner – ideally with a short USB extension cable

For FM scanning a TEF6686 tuner can be used instead of an RTL-SDR. This is optional; the normal RTL-SDR setup remains supported.

Here's a complete Amazon shopping list, including optional parts but excluding any temporarily required equipment:

https://amzn.to/2DtgQo8 

Alternatively, go to https://www.amazon.de/ and select "Find List" in the "My Lists" menu, then search for "fmlist."

:warning: Please note: some items are included multiple times as an alternative or in case of supply shortages! Unfortunately, some items **cannot** be shipped outside of Germany :de:

<a id="section-3"></a>
# 3 Setup

<a id="section-3-1"></a>
## 3.1 Preparing the Micro SD Card

First, you need to download an operating system image to your PC or laptop. Depending on the amount of time you want to invest, you'll need to choose an image. 64-bit and 32-bit versions of Raspberry Pi OS are now available:

https://www.raspberrypi.com/software/operating-systems/

Debian 13 (Trixie) and Debian 12 (Bookworm)  have been supported and tested with the scanner. Older versions based on Debian 9 (Stretch) or Debian 10 (Buster) or Debian 11 (Bullseye) can theoretically still be used, but their support ended several years ago.

Note: Armbian is not supported due to `sudo` problems.


https://de.wikipedia.org/wiki/Debian

Next, you need to follow the steps in [section 3.2.3 "Setting up the Raspberry Pi OS image - manually installing FMLIST_Scan"](#section-3-2-3) and [4.1 "Installing the scanner"](#section-4-1).

If you don't want to invest quite so much time, you can download a ready-made image for a Raspberry Pi 3B or 3B+, including pre-installed software and a scanner. It takes up approximately 6.5 GB of space when unpacked and is based on the (older) Raspbian image with desktop from November 13, 2018:

https://drive.google.com/drive/folders/11NYMjgJuYaQGRc15-NkYrLblvWgHeep3?usp=sharing

⚠️ Caution: This image does not (yet) work on a Raspberry Pi 4, as it is based on Stretch, and the screen will remain dark, for example! The files are also outdated, so you may encounter problems during installation!

:information_source: Note: [Sections 3.2.2](#section-3-2-2) and [4.1](#section-4-1) are omitted with this image.

While the selected image is being downloaded and written, you can begin assembling the hardware (Raspberry Pi heatsink, fan, ATX LEDs, and buttons). See [Section 4.3 Connecting ATX Buttons, LEDs, and Beepers](#section-4-3).

On Windows, you will need a program to unpack the compressed `.img.gz` image, e.g., **7-Zip**: http://www.7-zip.de/ . After downloading the compressed image and installing 7-Zip, unpack the image.

Insert the micro SD card.

To write the image to the micro SD card, see the instructions at https://www.raspberrypi.org/documentation/installation/installing-images/README.md

On Windows, **Etcher** is also required: https://www.balena.io/etcher/ . Etcher can write compressed images (`.zip`, `.gz`, and others) to the SD card without first unpacking.

⚠️ Follow the instructions very carefully! You don't want to overwrite the wrong drive!

If the existing monitor doesn't support the required high resolution – or if in doubt:

1. Remove the SD card and reinsert it.
2. DO NOT format it!
3. Open the drive (boot partition).
4. Open the `config.txt` file with a text editor.
5. In the line with `hdmi_safe=1`, remove the hash symbol `#` at the beginning of the line.
6. Save the file, close the editor, and safely remove the SD card.

To be able to work with SSH immediately:

Create an empty file named `ssh` (without an extension) in the drive. Remove the extension later if necessary.

⚠️ NOTE: Windows does not display file extensions by default. If necessary, run these commands at the Windows command prompt:      

```
D:
```
If necessary, change the letter. This means: switch to drive D: on the SD card.

```
type NUL >ssh
```
create an empty “ssh” file

```
dir
```
Now the file is checked

```
exit
```
End the prompt

To ensure the Raspberry Pi connects to the Wi-Fi network right from the start (read the gray box for group setup in Chapter 3.2 first!):

Create a `wpa_supplicant.conf` file in your drive. Enter the following content in a text editor:
      
```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=DE

network={
ssid="IHR_NETZWERK_NAME"
psk="IHR_NETZWERK_PASSWORT"
}
```

For operation on multiple networks, multiple `network` sections can be specified. Networks can be customized later—after installation—by editing the `/etc/wpa_supplicant/wpa_supplicant.conf` file.

<a id="section-3-2"></a>
## 3.2 Setting up the Raspberry Pi OS system

<a id="section-3-2-1"></a>
### 3.2.1 General

The default settings for both installation variants (in [sections 3.2.2](#section-3-2-2) and [3.2.3](#section-3-2-3)) are:

Type|Code
--- | ---
Computer name | `raspberrypi`
Username | `pi`
Password | `raspberry`

When entering the password using the manual installation via [3.2.3](#section-3-2-3), please ensure that the US :us: keyboard layout is still present. Therefore, <kbd>y</kbd> and <kbd>z</kbd> are swapped!

<a id="section-3-2-2"></a>
### 3.2.2 Setup using a prepared FMLIST_SCAN image

The prepared image for a Raspberry 3B+ and 3B (not 4B) can be downloaded from the following link: https://drive.google.com/drive/folders/11NYMjgJuYaQGRc15-NkYrLblvWgHeep3?usp=sharing

⚠️ Note: The password for the image from October 17, 2019, is `scanner123`.

It must be written to the SD card as described in the previous [section 3.1 Preparing the Micro SD Card](#section-3-1).

Despite the pre-installed software, further steps are still necessary:

1. Change the password, change the computer/hostname;
e.g., in the GUI via the main menu (raspberry in the top left corner), then Preferences and "Raspberry Pi Configuration".
2. In the "Raspberry Pi Configuration" dialog, you may want to consider disabling the GUI and booting "To CLI." Or disabling automatic login.
3. WLAN settings can be configured in several ways:
3.1 In the GUI, top right
3.2 Open Terminal / Xterm: there, type `sudo raspi-config` and select 2 Network Options and N2 Wi-fi
3.3 Edit the file with `sudo nano /etc/wpa_supplicant/wpa_supplicant.conf`. The information you need to enter here can be found, for example, in [section 3.1 Preparing the Micro SD Card](#section-3-1).
4. Expand the partition size to fit the entire SD card:
Open Terminal / Xterm: there, type `sudo raspi-config` and select `7 Advanced Options, A1 Expand Filesystem`. A reboot is required afterward.
5. Adjust the fmlist_scan configuration;
See the end of [Section 4.2 Configuration and Automatic Activation of the Scanner](#section-4-2).

Update the system and then restart to activate the new configuration:

```
sudo apt-get update && apt-get upgrade && reboot now
```

:warning: On the current image, `sudo apt-get upgrade` reports the error message

> The following packages have unmet dependencies

with `vlc-bin` and `E: Broken packages` at the end. Manually installing vlc-bin helps:

```
sudo apt install vlc-bin
```

<a id="section-3-2-3"></a>
### 3.2.3 Setting up the Raspberry Pi OS image – manually installing FMLIST_Scan

After the micro SD card with the Raspberry Pi OS operating system has been prepared, you can start the system for the first time:

1. Insert the micro SD card into the Raspberry Pi
2. If necessary, connect the monitor via HDMI, USB keyboard, USB flash drive, and possibly also Ethernet
3. Finally, connect the power supply (please only use recommended power supplies!)

For group setups on the same network/Wi-Fi (e.g., in a workshop), all devices would have the same conflicting computer name! Therefore, all steps up to and including changing the computer name must be performed individually. So, agree on the order, then exit `raspi-config` and shut down the Raspberry Pi with

```
sudo reboot now
```

so that the next participant can get started. Alternatively, you can configure directly via the keyboard/screen until the computer name is set up, including the reboot.

You can now see the Raspberry Pi OS system booting with the hostname `raspberrypi` until you reach the login screen.

1. The username is `pi`
2. The password is `raspberry`. When entering this password, make sure that you are still using the US keyboard layout. Therefore, <kbd>y</kbd> and <kbd>z</kbd> are swapped!

If you have enabled SSH and connected your network or configured your Wi-Fi correctly, you can connect via SSH/PuTTY. The keys for logging in and entering your password are not swapped due to remote access. From a Linux operating system, simply enter

```
ssh pi@raspberrypi
```

to connect.

For convenient access from a Windows PC, installing Samba is a good choice. Samba can provide a Windows-compatible network share for files on the Raspberry Pi. It is optional; WinSCP is simpler for occasional file transfers.

Install Samba with:

```
sudo apt install samba
```

After installation, configure the required share in `/etc/samba/smb.conf`, create or set a Samba password with `sudo smbpasswd -a pi`, and restart the service with `sudo systemctl restart smbd`. Do not share the whole system or expose Samba directly to the Internet.

You will then see the `$` prompt. You can enter commands here. The `$` indicates that you are logged in as a "normal" user.

With the command

```
sudo
```

individual administration commands can be launched, e.g., for installing software. If you want to enter multiple administration commands at once, start a new command prompt with

```
sudo bash
```

which announces itself with `#`. Here, you can enter the administration commands **without** the additional `sudo`. With

```
exit
```

you exit the command prompt or log off the system.

In the following, the `$` indicates that a command should be entered. The `#` character and the following text are comments; neither of these should be entered and are provided only for clarity.

The configuration starts with

```
sudo raspi-config
```

Note: In the US keyboard layout, <kbd>-</kbd> is located on the <kbd>ß</kbd> key.

A text-based menu opens:

1. Set keyboard layout – only works when logged in directly (without SSH):

```
4 Localisation Options → I3 Change Keyboard Layout → Generic 105 key (Intl) PC
→ Other → German → German (eliminate dead keys)
→ Enter (default for AltGr) → Enter (default for Compose key = No)
    • Change the password for user pi:
1 Change User Password
    • Set a unique computer name:
2 Network Options → N1 Hostname → 
e.g. rpi001, rpi002, scanner001, or any name of your choice
The name should appear in your home router, so that you can note the IP address(es),
especially for Wi-Fi. If necessary, you can reserve the IP address in the router so that it does not change automatically.
    • Configure Wi-Fi if it has not already been configured through wpa_supplicant.conf:
2 Network Options → N2 Wi-fi → DE → SSID → passphrase
    • Optionally change the network interface names:
2 Network Options → N3 Network interface names → No
    • Set the time zone:
4 Localisation Options → I2 Change Timezone → None of the above → UTC
    • Set the languages:
4 Localisation Options → I1 Change Locale → select and confirm all de_DE_* and en_US_* entries, plus any others you need. Then set the default, e.g. "C.UTF-8".
    • Set the Wi-Fi region:
4 Localisation Options → I4 Change Wi-fi Country → DE Germany
    • Enable SSH for remote access if it has not already been configured through the `ssh` file:
5 Interfacing Options → P2 SSH → Yes (SSH server)
    • If graphics are not needed, reduce the graphics memory so that more remains available to the scanner:
7 Advanced Options → A3 Memory split → 16
    • Always use the 3.5 mm jack for audio output, independently of HDMI use:
7 Advanced Options → A4 Audio → 1 Force 3.5mm
    • Update the system:
8 Update
    • Exit the configuration program
Finish → press the Tab key (to the left of Q), then press Enter
```

Update the system and then restart to activate the new configuration:

```
sudo apt-get update && apt-get upgrade && reboot now
```

Due to the change in the computer name, the next login via SSH/PuTTY must be confirmed accordingly.

Then log in at the login screen with the newly assigned password, unplug/disconnect the network cable if necessary, and check the IP address(es):

```
ifconfig
```

Check the IP address on the router and fix it so that the Raspberry Pi always receives the same address.

You can now log out of the Raspberry Pi locally and log in via SSH or PuTTY (Windows, http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html). This only works if the SSID and passphrase are configured correctly; repeat the configuration if necessary.

Under Windows, you should also install **WinSCP** for file transfer: https://winscp.net/ . For wired access with your laptop while on the go, see http://www.dhcpserver.de/cms/ . For setting up multiple WLANs, see http://bit.ly/2xO4H7T (stackexchange.com).

<a id="section-4"></a>
# 4 Setting up the scanner

<a id="section-4-1"></a>
## 4.1 Installing the scanner

This section can be skipped if you are using the prepared image for a Raspberry 3B or 3B+ as described in [section 3.2.2](#section-3-2-2).

The following commands must be entered at the command prompt (local or SSH) of the Raspberry Pi system.

The scanner requires sudo privileges without prompting for a password. This is already configured for Raspberry Pi OS. Other operating systems may require this if `sudo bash` asks for a password:

```
sudo nano /etc/sudoers.d/010_user-nopasswd
```

The file name `010_user-nopasswd` can be customized to the username.

In the nano editor, enter the following line under "Customize the username user":

```
user ALL=(ALL) NOPASSWD:ALL
```

Use the correct username instead of `user`! Save the file and close the editor.

Downloading the scanner requires the version control system **git**. Install with:

```
sudo apt install -y git
```

Now log in as the appropriate user – usually `pi` – under which the scanner should also run.

Download the scanner source code:

```
git clone https://github.com/hayguen/fmlist_scan.git
cd fmlist_scan
```

The most important installation parameters can be adjusted in the `setup.sh` file:

```
cat setup.sh
#export FMLIST_SCAN_USER="hayguen"	# default user "pi"
#export FMLIST_SCAN_RASPI="0"		# default "1" if Raspberry Pi hardware
```

The user name can be adjusted in the line with `FMLIST_SCAN_USER`. The line with `FMLIST_SCAN_RASPI` indicates that the hardware is a Raspberry Pi.

⚠️ Important: When making adjustments, the comment character `#` at the beginning of the line must be removed.

```
nano setup.sh
```

Then start the installation (as superuser) with:

```
sudo ./setup.sh
```

If necessary, monitor the temperature in a second SSH session:

```
while true; do cat /sys/class/thermal/thermal_zone0/temp ; sleep 3 ; done
```

This step takes a while because additional software for the Raspberry Pi OS system is downloaded and installed. Furthermore, some programs are downloaded from GitHub in source code, compiled (built), and installed. So you have plenty of time for a cup of tea or coffee ☕ :wink:

After installation, you should check the configuration file(s):

Command | Explanation
--|--
`sudo nano /etc/fstab` | Check device for USB flash drive!
`crontab -e` | Automatically start the scanner on @reboot<br>Note: The "#" can be commented out


<a id="section-4-2"></a>
## 4.2 Configuring and Automatically Activating the Scanner

The configuration can be edited with the following command.

ℹ️ It's best to take your time with this step and read through the comments carefully!

```
nano ~/.config/fmlist_scan/config
```

The file `~/.config/fmlist_scan/config` contains the most important scanner settings:

Setting | Notes
--|--
FMLIST_SCAN_DEAD_REBOOT | Set to 1 so that the system automatically restarts when errors are detected.
FMLIST_SCAN_AUTOSTART | specifies that the scanner starts automatically with the system.
FMLIST_SCAN_FM | specifies whether VHF/FM should be scanned.
FMLIST_SCAN_DAB | specifies whether DAB/DAB+ should be scanned.
FMLIST_SCAN_GPS_* | specifies whether/when the scanner operates in stationary or mobile mode. The stationary GPS coordinates are also specified here.
FMLIST_SCAN_SAVE_PWMTONE | specifies whether a tone sequence should be played with the connected piezo beeper when the scan results are saved.
FMLIST_SCAN_SAVE_LEDPLAY | specifies whether the connected LEDs should switch when the scan results are saved.
FMLIST_SCAN_FOUND_PWMTONE | Specifies whether the connected piezo beeper should play a sequence of tones with each carrier/station found.
FMLIST_SCAN_FOUND_LEDPLAY | Specifies whether the connected LEDs should switch with each carrier/station found.
FMLIST_SCAN_PWM_FEEDBACK | Specifies whether the connected piezo beeper should play a sequence of tones with each complete FM/DAB scan. Test/listen with `scanToneFeedback.sh`:<br>FM success (at least 1 station): short short short<br>FM failure: short short long<br>DAB success (at least 1 station): short long short<br>DAB failure: short long long


The files `~/.config/fmlist_scan/fmscan.inc` and `~/.config/fmlist_scan/dabscan.inc` contain additional settings that particularly affect scanning speed and thoroughness.

Final system update and reboot with:

```
sudo apt remove default-jre-headless openjdk-8-jre-headless:armhf
sudo apt remove ca-certificates-java
sudo apt-get update && apt-get upgrade && reboot now
```

If necessary, calibrate the RTL-SDR stick after rebooting:

```
kal.sh
```
(Note: The background scan process must be stopped!)

<a id="section-4-2-1"></a>
### 4.2.1 TEF6686 and detailed DAB analysis

The TEF6686 FM backend can use a serial connection or a network connection. Set `FMLIST_FM_BACKEND=tef` to use it. The main settings are `FMLIST_TEF_TRANSPORT`, `FMLIST_TEF_SERIAL_PORT`, `FMLIST_TEF_TCP_HOST`, and `FMLIST_TEF_TCP_PORT`. Network discovery can find a TEF device automatically when `FMLIST_TEF_TCP_HOST_AUTO=1`.

In mobile mode, the TEF6686 uses seek scanning to find stations quickly. It then spends more time on the found frequencies to decode RDS. In fixed mode, the scanner can spend more time on each frequency.

The ABRA DAB scanner can check audio services in detail. This can report the audio codec, bitrate, protection level, language, and program type. Weak or silent services are reported as such instead of receiving unreliable values. Detailed analysis takes longer.

To enable DAB analysis from a recording, set `FMLIST_SCAN_DAB_ANALYZE_FROM_RAW=1`. To scan FM and DAB at the same time, set `FMLIST_SCAN_PARALLEL_FM_DAB=1`. This is supported for TEF FM together with RTL-SDR DAB and is off by default. Keep `FMLIST_SCAN_DAB_RAW_PARALLEL_JOBS=1` on a Raspberry Pi with little RAM.

<a id="section-4-2-2"></a>
### 4.2.2 Webserver

The scanner includes a small webserver for use on the local network. It can show scan results, configure the scanner, configure Wi-Fi, and test tones.

The webserver is installed by default during the normal setup. To install it separately, run this in the `src` directory:

```
sudo -E ./setup.sh wsrv
```

The service listens on port `8000`. Open `http://<Raspberry-Pi-IP>:8000/` in a browser. The initial password is `scanner123`; change it immediately in the web interface under "Change Config Passphrase".

Use the service commands below to check or restart the webserver:

```
sudo systemctl status scan-webserver.service
sudo systemctl restart scan-webserver.service
```

The webserver uses HTTP and is intended for trusted local networks. Do not expose it directly to the Internet.

<a id="section-4-2-3"></a>
### 4.2.3 SideDoor remote access

SideDoor creates an SSH reverse tunnel from the Raspberry Pi to the project's JumpServer. It is optional and is intended for remote support or service access.

Ask the administrator for the JumpServer settings and a unique gateway port between `8000` and `8999`, then edit `src/sidedoor_config`. Run the setup from the `src` directory:

```
sudo -E ./setup_sidedoor <gateway-port>
```

The setup installs the required packages, creates the SSH keys, configures the dedicated service user, and enables the `sidedoor` systemd service. Send the generated public key `src/sidedoor-key/id_rsa.pub` to the administrator when requested.

Check the tunnel with `sudo systemctl status sidedoor`. Do not enable SideDoor unless remote access has been agreed with the administrator.

<a id="section-4-3"></a>
## 4.3 Connecting ATX Buttons, LEDs, and Beepers

The Raspberry Pi has two pin headers that are physically labeled (top column "Physical"). The wiringPi software (http://wiringpi.com/, top column "wPi") uses different numbering.

The right column above, with physical pins 2, 4, 6, .., 40, is on the outside of the Raspberry Pi. Pin 40 is near the USB ports. The left column, with the odd-numbered pins, is on the inside of the Raspberry Pi board.

An overview of all pins can be found with

```
gpio readall
```

```
 +-----+-----+---------+------+---+---Pi 3+--+---+------+---------+-----+-----+
 | BCM | wPi |   Name  | Mode | V | Physical | V | Mode | Name    | wPi | BCM |
 +-----+-----+---------+------+---+----++----+---+------+---------+-----+-----+
 |     |     |    3.3v |      |   |  1 || 2  |   |      | 5v      |     |     |
 |   2 |   8 |   SDA.1 |   IN | 1 |  3 || 4  |   |      | 5v      |     |     |
 |   3 |   9 |   SCL.1 |   IN | 1 |  5 || 6  |   |      | 0v      |     |     |
 |   4 |   7 | GPIO. 7 |   IN | 1 |  7 || 8  | 0 | IN   | TxD     | 15  | 14  |
 |     |     |      0v |      |   |  9 || 10 | 1 | IN   | RxD     | 16  | 15  |
 |  17 |   0 | GPIO. 0 |   IN | 0 | 11 || 12 | 0 | OUT  | GPIO. 1 | 1   | 18  |
 |  27 |   2 | GPIO. 2 |   IN | 0 | 13 || 14 |   |      | 0v      |     |     |
 |  22 |   3 | GPIO. 3 |   IN | 0 | 15 || 16 | 0 | IN   | GPIO. 4 | 4   | 23  |
 |     |     |    3.3v |      |   | 17 || 18 | 0 | IN   | GPIO. 5 | 5   | 24  |
 |  10 |  12 |    MOSI |   IN | 0 | 19 || 20 |   |      | 0v      |     |     |
 |   9 |  13 |    MISO |   IN | 0 | 21 || 22 | 0 | IN   | GPIO. 6 | 6   | 25  |
 |  11 |  14 |    SCLK |   IN | 0 | 23 || 24 | 1 | IN   | CE0     | 10  | 8   |
 |     |     |      0v |      |   | 25 || 26 | 1 | IN   | CE1     | 11  | 7   |
 |   0 |  30 |   SDA.0 |   IN | 1 | 27 || 28 | 1 | IN   | SCL.0   | 31  | 1   |
 |   5 |  21 | GPIO.21 |   IN | 1 | 29 || 30 |   |      | 0v      |     |     |
 |   6 |  22 | GPIO.22 |   IN | 1 | 31 || 32 | 0 | OUT  | GPIO.26 | 26  | 12  |
 |  13 |  23 | GPIO.23 |   IN | 0 | 33 || 34 |   |      | 0v      |     |     |
 |  19 |  24 | GPIO.24 |   IN | 0 | 35 || 36 | 0 | OUT  | GPIO.27 | 27  | 16  |
 |  26 |  25 | GPIO.25 |   IN | 0 | 37 || 38 | 0 | IN   | GPIO.28 | 28  | 20  |
 |     |     |      0v |      |   | 39 || 40 | 0 | IN   | GPIO.29 | 29  | 21  |
 +-----+-----+---------+------+---+----++----+---+------+---------+-----+-----+
 | BCM | wPi |   Name  | Mode | V | Physical | V | Mode | Name    | wPi | BCM |
 +-----+-----+---------+------+---+---Pi 3+--+---+------+---------+-----+-----+
```

<a id="section-4-3-1"></a>
### 4.3.1 CPU Fan Connection

ℹ️ The connection may vary depending on the model. Therefore, refer to the manufacturer's information!

<a id="section-4-3-2"></a>
### 4.3.2 Piezo Beeper Connection

The beeper is connected to physical pins 12 (+) and 14 (ground/GND). Test with the following commands:

Command | Meaning
--| --
`gpio mode 1 pwm` | physical pin 12 corresponds to pin 1 on wiringPi
`gpio pwmTone 1 2000` | sound on
`gpio pwmTone 1 0` | sound off

<a id="section-4-3-3"></a>
### 4.3.3 ATX Button and LED Connection

The ATX shutdown button is connected to physical pins 39 and 40. Test:

Commands | Notes
--|--
`sudo systemctl stop gpio-input` | Disable the service first
`gpio mode 29 up` | Physical pin 40 corresponds to pin 29 on wiringPi
`gpio read 29` | Must return 1 if the button is not pressed,<br>must return 0 if the button is pressed

The green LED is connected to physical pin 36 (wiringPi: 27), ground to pin 34.
The red LED is connected to physical pin 32 (wiringPi: 26), ground to pin 30. Test:

Commands | Notes
--|--
`gpio mode 27 output` | wiringPi: 27 for green, 26 for red
`gpio write 27 on` | The respective (here: green) LED is lit
`gpio write 27 off` | The respective LED goes out.

After testing the buttons, reactivate the service:

```
sudo systemctl start gpio-input
```
![atx_schema](https://github.com/user-attachments/assets/d91d130c-ec5a-4a40-b80f-832eae80de3a)
![atx_foto](https://github.com/user-attachments/assets/f3651a06-0161-4a23-b909-9b80be5f4da1)

<a id="section-5"></a>
# 5. Operating the Scanner

<a id="section-5-1"></a>
## 5.1 Login / IP Address

<a id="section-5-1-1"></a>
### 5.1.1 IP Address

If you have connected the Raspberry Pi to a screen and keyboard, you can log in directly. If you haven't made any changes to the computer name and password, the login details from [Section 3.2.3](#section-3-2-3) apply:

1. The username is `pi`
2. The password is `raspberry`. When entering the password, make sure that you are using a US keyboard layout. In this case, <kbd>y</kbd> and <kbd>z</kbd>, as well as various special characters, are swapped!

After logging in, you can also display the IP address(es) using the `ipconfig` command.

Alternatively, you can connect the Raspberry Pi – without a screen/keyboard – and let the home router automatically assign an IP address. The assigned IP address can probably be viewed in the router configuration/status page on your PC. Depending on the router, the Raspberry Pi should be recognized by the hostname `raspberrypi`.


If you don't have access to the router, you can determine the IP address on your PC using the command

```
ping raspberrypi
```

in the DOS box – if the router supports DNS. If you already adjusted the hostname during installation, the ping command must be adjusted accordingly. The DOS box is listed as a "command prompt" in the Windows Start menu.

If the router doesn't support DNS, you have to check the router menu to see which new IP address is added when the Raspberry Pi starts up. If you find that DNS is working, you can also use the hostname for SSH/SCP.

<a id="section-5-1-2"></a>
### 5.1.2 Operating Software for PC

To control the Raspberry Pi and scanner from the PC, you need software for SSH and SCP. A Linux PC usually comes with this software already installed. For Windows, appropriate software may need to be installed:

#### SSH for remote console:
PuTTY http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html

#### SCP for file transfer:
WinSCP https://winscp.net/
#### Optional for wired access with a laptop while on the go:
http://www.dhcpserver.de/cms/
#### Unpacker for compressed scan results
e.g., 7-zip: http://www.7-zip.de/
#### Viewer for scan results in .csv file format
For easy import, LibreOffice / Calc is recommended, which displays a simple import dialog for delimiters and UTF-8 character encoding: https://de.libreoffice.org/
#### Editor, e.g., for configuration files:
Notepad++: https://notepad-plus-plus.org/

We recommend installing PuTTY and WinSCP through the PortableApps software package https://portableapps.com/. Various other software, such as TeamViewer, is also available through PortableApps. Even when used from a USB flash drive, PortableApps checks regularly for updates.

ℹ️ When installing PortableApps, paths such as `C:\Program Files` or `C:\Program Files (x86)` are not recommended, as normal users do not have write permissions in these paths.

To be able to use files directly from Explorer by double-clicking or using the "Open with" option, **7zip**, **Notepad++**, and **LibreOffice** should be installed directly – without PortableApps.

<a id="section-5-1-3"></a>
### 5.1.3 Software for Android Smartphones

For SSH, the free apps **ConnectBot** and **JuiceSSH** are recommended. Use **Total Commander** for editing and renaming files, and **VNC Viewer** to display the Raspberry Pi screen on the smartphone.

<a id="section-5-2"></a>
## 5.2 Adjusting the Configuration / Additional Wi-Fi

The scanner's configuration is done in the files located in the `/home/pi/.config/fmlist_scan/` folder, including config. These files can be edited within an SSH session using a simple editor such as `nano` or `mcedit`. If you edit the files from a PC, e.g., via **WinSCP**, please ensure that the line endings are correct (Unix: LF)! **Notepad++** is recommended as a Windows editor.

As an alternative to direct editing, it is not always possible to log in via the IP address of the home network, for example, in unfamiliar environments. With the Raspberry Pi turned off, you can remove the USB flash drive and make configuration adjustments there: for example, you can also set up another/additional Wi-Fi network.

The configuration files can be edited from a PC. Using an OTG USB adapter, it is also possible to edit the configuration files with an Android smartphone:

![otg_adapter](https://github.com/user-attachments/assets/59116cda-022d-43d0-a39e-b8dc23a7a523)

The files from the `fmlist_scanner/config/` folder must be edited. The configuration files contain the last used state. The exception is `wpa_supplicant.conf`, so that unauthorized users cannot access the Wi-Fi passwords by removing them and reading them. The passwords are also stored on the Raspberry Pi, so they can be accessed by stealing them completely! In any case, new additional Wi-Fi networks can be added. This requires the exact SSID and key. In many cases, these are located on the back of the router.

Editing on a smartphone is not particularly convenient compared to a PC – but it can also be done on the go. After editing the file(s), the prefix `old_` must be removed from the filename of each edited file:

![total_commander](https://github.com/user-attachments/assets/c729eaa7-349d-466b-8f2c-e859d1455c8c)

After properly ejecting the USB drive, plugging in the Raspberry Pi, and turning it on, the new configuration will be automatically applied. This may take some time. For Wi-Fi, the LAN cable should not be connected from the start.

<a id="section-5-3"></a>
## 5.3 Status Messages

The scanner primarily reports its status via the piezo beeper. The detection of FM and DAB stations is reported via the tone sequences for each scan run. See [Section 4.2](#section-4-2) for the `FMLIST_SCAN_PWM_FEEDBACK` configuration entry:

Event | Tone Sequence
-- | --
FM success (at least 1 station) | short short short
FM failure | short short long
DAB success (at least 1 station) | short long short
DAB failure | short long long

In addition to these operating results, there are other tone sequences for:

1. Scanner startup
2. Error status, e.g., no RTL dongle found
3. Scan results saved

:information_source: Testing/listening is also possible with scanToneFeedback.sh (after logging in via SSH/PuTTY).

:information_source: The individual LED colors have no specific meaning. They are switched for each detected station. No switching occurs if the next station is detected within one second to limit the switching.

<a id="section-5-4"></a>
## 5.4 ATX Buttons

There are two ATX buttons, if they were connected.

The button closest to the USB connectors shuts down the Raspberry Pi properly when pressed once. After about 30 seconds, the power can be unplugged.

The other button stops the scanner if necessary and uploads all previous results – if an internet connection is available. In effect, the two commands from the following [section 5.6](#section-5-6) are executed.

<a id="section-5-5"></a>
## 5.5 At the Command Line (SSH or Local)

Command | Meaning
--|--
`screen -ls` | Displays running background processes
`screen -r scanLoopBg` | Switch to the background scan process, <kbd>Ctrl</kbd>+<kbd>c</kbd> to exit, <kbd>Ctrl</kbd>+<kbd>a</kbd> followed by <kbd>d</kbd> to send it back to the background.
`tail -f ~/ram/scanner.log` | Display the logs. Exit with <kbd>Ctrl</kbd>+<kbd>c</kbd>
`stopBgScanLoop.sh [wait]` | End any running background process. Use `screen -ls` to check. Alternatively, use the `wait` option without the `[` and `]` characters.
`startBgScanLoop.sh` | Start the scan process in the background.
`cdResults` | Go to the saved results.
`mc` | Use Midnight Commander to view the results.
`sudo shutdown now` | Shutdown – alternatively to the ATX button<br>alternatively, unplug the power after the "Save" tone sequence
`monitorBgScanLoop.sh` | simple script for monitoring the scanner
`checkScanConfig.sh` | check the configuration for missing entries
`listDABaudio` | Show DAB service, ensemble, codec, bitrate, and audio details in the current result folder.
`listDABprogs` | Show the DAB services found in the current result folder.
`listDABens` | Show the DAB ensembles found in the current result folder.
`listDABch <channel>` | Show results for one DAB channel, for example `listDABch 7D`.
`listDABeid <eid>` | Show results for one ensemble ID, for example `listDABeid 1234`.

Run these `listDAB` shortcuts after `cdResults` and after a scan has created result CSV files.

<a id="section-5-6"></a>
## 5.6 Results

<a id="section-5-6-1"></a>
### 5.6.1 Preparation and Upload

During operation, result files are stored on the USB flash drive under `/mnt/sda1/fmlist_scanner` (the default value of `FMLIST_SCAN_RESULT_DIR`), in subfolders named by date. The following command prepares the results for upload:

```
prepareScanResultsForUpload.sh [all]
```

Without the optional `all` argument, results up to the current day are prepared. With `all`, all data is processed, so the scanner should be temporarily deactivated beforehand.

The processed results are then located under `/mnt/sda1/fmlist_scanner/uploads`. The already processed files are moved to the folder `/mnt/sda1/fmlist_scanner/uploaded`.

The files can be copied during operation using scp or WinSCP and then deleted.

Alternatively, the "data transfer" takes place via the USB flash drive – after shutting down the system. Don't forget to reconnect the USB flash drive to the Raspberry Pi before starting up.

The processed results are uploaded using the following command:

```
uploadScanResults.sh
```

If the upload is successful, the data is not deleted – but moved to another folder. If the upload fails, e.g., due to a lost internet connection, the data remains in the processed folder.

An automatic upload of the processed results to FMList, e.g., via a cron job, does not occur. The cron job must be set up manually; For example, add the following line with `crontab -e`:

```
15 0 * * * bash -l /home/pi/bin/prepareScanResultsForUpload.sh ; bash -l /home/pi/bin/uploadScanResults.sh
```

Please note that everything goes on ONE line. The next version will already contain the line as a comment, so you only need to activate the entry. The first number indicates the minute; the second the hour. In this example, 00:15 – according to UTC. The time should be adjusted. If necessary, duplicate the entire line and specify different times!

<a id="section-5-6-2"></a>
### 5.6.2 Online Analysis

Online analyses from the FMList database can be viewed at https://www.fmlist.org/ after logging in and selecting the "URDS" menu item. The URDS menu item only appears if you have the necessary access rights. Contact Günter Lorenz <glorenz@fmlist.org> by email to ask whether you can obtain access.

<a id="section-5-6-3"></a>
### 5.6.3 Manual Analysis

After preparing the data (see [Section 5.6.1](#section-5-6-1)), copying it to the PC (WinSCP), and unpacking it (7zip), the *.csv file can be opened with a text editor or LibreOffice. An import dialog appears in the latter case. For correct umlauts, the character set must be set to "Unicode (UTF-8)." The remaining settings are usually correct:

![text_import](https://github.com/user-attachments/assets/a2a84418-94da-4b65-b924-271ce7f1f6e0)

The file will be quite large and has a lot of columns. The column labels are missing, as they vary significantly for each group (group ID always in column 1).

The file is actually intended for automatic evaluation by FMList. Manual review was/is not the primary goal.

DAB Ensemble entries begin with group ID 20:

The first dozen columns are the time and GPS coordinates. The large numeric value on the left is the "UNIXTIME" value.

Code | Meaning
--|--
`UNIXTIME` | Unix timestamp in seconds since January 1, 1970, 00:00 UTC

Followed by the GPS information:

Code | Meaning
--|--
`GPSLAT` | GPS Latitude
`GPSLON` | GPS Longitude
`GPSMODE` | GPS Mode (state: 2 = Lock without altitude; 3 = Lock including altitude)
`GPSALT` | GPS Altitude (for GPSMODE 3)
`GPSTIME` | GPS Time in UTC

For the last fields, there are rough orientation markers "fic", "snr", and "tii". The following columns are in the following order:

• "fic", min_fic, max_fic, num_fic, avg_fic:
These fic values ​​come from the DAB decoding and are merely statistically summarized. num_fic is the number of fic values ​​received.

• "snr", min_snr, max_snr, num_snr, avg_snr:
Snr columns "min_snr, max_snr, avg_snr" (without "snr, num_snr") are in whole dB. These snr values ​​come from DAB decoding. Reliability is difficult to assess.

min is the smallest of the received values, max is the largest, and avg is the arithmetic mean.

• "tii", tii_id, num, max(avg_snr), max(min_snr), max(next_snr):
tii columns "max(avg_snr), max(min_snr), max(next_snr)" (without "tii,tii_id,num") are in tenths of dB. SNR (avg and min) refers solely to the spectral power in the null symbol with the TII carriers. The assumed TII carrier power is considered in relation to the weaker noise "carriers."
Using the dB value, "phantom" TIIs should be eliminated. The output is currently unfiltered to gather some statistics before suppressing TIIs with too low values.
Next_SNR indicates the SNR distance to the next best main or sub-ID and thus provides a measure of confusion: the smaller next_snr, the less reliable.
If multiple TIIs are detected, they simply follow a blank column.

The audio programs of an ensemble are listed in the rows with group ID 21.

The data programs begin with group ID 22.

FM stations with RDS begin with group ID 30:

Here is an example line including the column identifiers:

```
30, 1560712920:UNIXTIME,freq,91400000, RDS:1, SNRmin:198, SNRmax:272,2019-06-16T19:22:00.046988951 Z:SYSTIME,48.885590906:GPSLAT,8.702782767:GPSLON,3:GPSMODE,293.611:GPSALT,2019-06-16T19:21:59.000Z:GPSTIME, PI:0xD30C, NPI:40, PS:" welle ", NPS:3, TA:0, TP:1, MUSIC:1, PTY:"Pop music", GRP:"0A", STEREO:0, DYNPTY:1, OTHER_PI:, ,"allps:", "die neue"," welle ",,
```

All decoded PS entries are placed after the column containing "allps:".

Code | Meaning
--|--
UNIXTIME| Unix timestamp in seconds since January 1, 1970 00:00 UTC
SYSTIME| Operating system time in UTC
GPSLAT| GPS latitude
GPSLON| GPS longitude
GPSMODE| GPS mode (state: 2 = lock without altitude; 3 = lock including altitude)
GPSALT| GPS altitude (for GPSMODE 3)
GPSTIME| GPS time in UTC
RDS| RDS present? (0 / 1)
SNRmin| minSNR in tenths of dB from `checkSpectrumForCarrier` (preScan)
SNRmax| maxSNR in tenths of dB
PI| PI code
NPI | how often this PI code was received/decoded
PS| Program station
NPS| how often this PS was received/decoded
TA| Traffic announcement (traffic announcement active)
TP| Traffic program (traffic program station)
MUSIC| Music program (as opposed to speech program)
PTY | Program Type
GRP | RDS Groups
STEREO | Stereo

Further FM stations without successful RDS decoding begin with group ID 31.

<a id="section-5-7"></a>
## 5.7 Recordings and Upload

After stopping the scanner (`stopBgScanLoop.sh wait`, see [section 5.5](#section-5-5)), signals can be recorded manually. VHF/FM recordings are triggered with

```
recWFMchunk.sh <frequency in MHz> <duration in seconds> [<options to rtl_sdr>]
```

For security reasons, the recording is first made in RAM (`/dev/shm/`) and is then copied to the USB flash drive and deleted from RAM. Therefore, only recordings of limited duration can be created. The `-g` option for manual gain or amplification and the `-H` option for the wave file format are particularly interesting. The `-H` option must be specified immediately after the recording duration to ensure the file name is generated appropriately. With the wave file format, the file can be opened directly with SDR software such as HDSDR without an additional import step. Example:

```
recWFMchunk.sh 100.7 20 -H -g 20.7
```

`rtl_test` displays the possible gain values. Stop it with <kbd>Ctrl</kbd> + <kbd>c</kbd>.

The following gain values ​​are possible with the R820T(2) tuner:

Values|Values|Values
--|--|--
0.0 | 0.9 | 1.4
2.7 | 3.7 | 7.7
8.7 | 12.5 | 14.4
15.7 | 16.6 | 19.7
20.7 | 22.9 | 25.4
28.0 | 29.7 | 32.8
33.8 | 36.4 | 37.2
38.6 | 40.2 | 42.1
43.4 | 43.9 | 44.5
48.0 | 49.6

:information_source: For other values ​​in dB, the closest value is used.

Similar to recording FM channels, DAB channels can be conveniently recorded:

```
recDAB.sh <channel> <duration in seconds> [<options to rtl_sdr>]
```

In addition to amplifying the tuner, the bias voltage for a suitable external preamplifier can be activated – if available – with a V3 RTL dongle from rtl-sdr.com using the option `-O T=1`. For example:

```
recDAB.sh 5C 4 -H -g 0.9 -O T=1
```

The recording option is particularly useful for testing and verification purposes, e.g., checking the AGC behavior for clipping. Furthermore, the scanner's sensitivity can be compared with other software. An initial analysis can be performed for short files (low RAM) using the audio editor "Audacity," which is preinstalled in the image.

The recording file name automatically includes all relevant metadata such as frequency/channel, sample rate, and GPS coordinates. The exact storage location is displayed after copying to the USB flash drive.

Test data can easily be provided to the developer, Hayati Aygün, with the following commands:

```
cd /mnt/sda1/fmlist_scanner/IQrecords/
uploadScanFilesToDeveloper.sh <target_foldername> <filenames>
```

Use an identifier as the target folder name. For example:

```
uploadScanFilesToDeveloper.sh HansMeier DAB-5C_2019-03-...
```

Please note that the tab key <kbd>TAB</kbd>, to the left of <kbd>Q</kbd> on a German keyboard, is used to complete filenames. Alternatively, the shell (bash) can also use `*` to complete all matching filenames. If you provide files this way, please let me know by email what they are. I should also be able to get back to you...

<a id="section-5-8"></a>
## 5.8 Problems and Possible Solutions

### Nothing happens at all

1. Check the power supply. Test with a different (USB) cable.
2. Remove and reinsert the SD card.

### After switching on, it beeps a few times (long, long, long), the red LED flashes, and everything repeats.

Unplug and reconnect the RTL-SDR. If the problem persists, unplug and reconnect the power.

### Raspberry Pi no longer accessible after pressing the reboot button.

Sometimes the system freezes during reboot. Disconnect and reconnect power.

### Poor reception quality

1. Check the antenna connection and connector, as well as the antenna's location!

2. Is the gain set correctly?

3. Is the car window metal-coated?

### The scanner freezes after a while.

1. The RTL dongle is apparently not particularly stable.
2. Enable automatic reboot with the setting `FMLIST_SCAN_DEAD_REBOOT=“1“` in the file `/home/pi/.config/fmlist_scan/config`. If necessary, also reduce the setting `FMLIST_SCAN_DEAD_TIME`, e.g., to `240`.

### Stations are not recognized or decoded.

There can be various reasons for this. The specific cause is best determined by looking at a recording. The utilities `recWFMchunk.sh` and `recDAB.sh` are included/installed for this purpose. Please create and provide recordings of 10-30 seconds.

### The beeper is too loud and may be annoying too often:

1. The configuration allows you to specify when the beeper sounds. This can reduce or increase the frequency.
2. The opening of the beeper can be partially or completely sealed with adhesive tape. You may have to experiment with the volume here.
3. If you don't want to hear anything at all for a while, we recommend simply unplugging one of the two pins. When reattaching, pay attention to the polarity: (+) symbol on the piezo.


### After unplugging the LAN cable, the Wi-Fi SSH/PuTTY session also freezes.

This is a known issue. Do not use the LAN cable for Wi-Fi operation.

For other or persistent problems, please first register for the mailing list https://groups.io/g/fmlist-scanner and then send an email to <fmlist-scanner@groups.io>.

More information about new versions/updates or questions/answers from you will be available via this list in the future. Additional photos, links, and wiki pages are also available on the mailing list website.


