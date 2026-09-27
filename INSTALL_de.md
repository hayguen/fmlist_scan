# Einrichtung und Betrieb von FMLIST_Scan auf einem Raspberry Pi 3B+, 3B oder 4B

For English version see [Installation instructions in English](INSTALL_en.md)

## Autor: 
Hayati Aygün (E-Mail: <h_ayguen@web.de>, Portierung auf Markdown durch Andreas Mikula (E-Mail: <andimik@yahoo.de>)

## GPG Fingerprint:	
`558E C9EF 3EAB 05E8 76AF 61DC D44C 9772 6FA1 CC0B`

## Inhaltsverzeichnis

- [1 Einleitung](#section-1)
- [2 Voraussetzungen](#section-2)
- [3 Setup](#section-3)
    - [3.1 Micro SD-Karte vorbereiten](#section-3-1)
    - [3.2 Einrichtung des Raspberry OS Systems](#section-3-2)
        - [3.2.1 Allgemein](#section-3-2-1)
        - [3.2.2 Einrichtung mittels vorbereitetem FMLIST_SCAN Image](#section-3-2-2)
        - [3.2.3 Raspberry OS Image einrichten](#section-3-2-3)
- [4 Einrichtung des Scanners](#section-4)
    - [4.1 Installation des Scanners](#section-4-1)
    - [4.2 Konfiguration und automatische Aktivierung des Scanners](#section-4-2)
        - [4.2.1 TEF6686 und detaillierte DAB-Audioauswertung](#section-4-2-1)
        - [4.2.2 Webserver](#section-4-2-2)
        - [4.2.3 SideDoor-Fernzugriff](#section-4-2-3)
    - [4.3 Anschluss von ATX-Tastern, LEDs und Piepser](#section-4-3)
        - [4.3.1 Anschluss CPU-Lüfter](#section-4-3-1)
        - [4.3.2 Anschluss Piezo-Piepser](#section-4-3-2)
        - [4.3.3 Anschluss ATX-Taster und LEDs](#section-4-3-3)
- [5 Betrieb des Scanners](#section-5)
    - [5.1 Anmeldung / IP-Adresse](#section-5-1)
        - [5.1.1 IP-Adresse](#section-5-1-1)
        - [5.1.2 Betriebs-Software für PC](#section-5-1-2)
        - [5.1.3 Software für’s Android Smartphone](#section-5-1-3)
    - [5.2 Anpassung der Konfiguration / zusätzliches WLAN](#section-5-2)
    - [5.3 Statusmeldungen](#section-5-3)
    - [5.4 ATX Taster](#section-5-4)
    - [5.5 An der Kommandozeile](#section-5-5)
    - [5.6 Ergebnisse](#section-5-6)
        - [5.6.1 Aufbereitung und Upload](#section-5-6-1)
        - [5.6.2 Online Auswertung](#section-5-6-2)
        - [5.6.3 Manuelle Auswertung](#section-5-6-3)
    - [5.7 Aufzeichnungen und Upload](#section-5-7)
    - [5.8 Probleme und mögliche Lösungen](#section-5-8)

<a id="section-1"></a>
# 1 Einleitung

**FMLIST_Scan**, im Folgenden als „Scanner“ bezeichnet, wurde von **Günter Lorenz** angeregt. Der Scanner soll Senderinformationen für die FMLIST (https://www.fmlist.org/, Senderdatenbank des UKW/TV-Arbeitskreises e.V.) sammeln. Das Projekt wurde erstmals am 8. September 2018 auf der UKW-Tagung in Weinheim (siehe https://ukw-tagung.org/) vorgestellt.

Das Manuskript ist unter https://codingspirit.de/Linux-ist-sexy-Freiheit-Skript.pdf abrufbar, die Folien unter https://codingspirit.de/Linux-ist-sexy-Freiheit-Folien.pdf

Manuskript und Folien werden ggf. noch aktualisiert, sodass die aktuelle Version immer über obige Links abgerufen werden sollten. Der aktuelle Stand des Quellcodes ist ebenfalls verfügbar: https://github.com/hayguen/fmlist_scan

<a id="section-2"></a>
# 2 Voraussetzungen

Die Anleitung bedarf folgender Voraussetzungen

1. Raspberry Pi 3B+ inkl. geeigneter Stromversorgung (Hinweise: ein Pi 3B funktioniert auch, für einen Pi 4 muss das Setup jedoch selbst ausgeführt werden)
2. Micro SD-Karte, 16 GB
3. USB-Speicherstick
4. ggf. Temporär: USB-Tastatur
5. ggf. Temporär: Bildschirm und ggf. Adapter vom HDMI Anschluss des Raspberry Pi
6. Temporär: PC oder Notebook, Micro SD Leser bzw. Adapter auf micro SD-Karte
7. WLAN oder Ethernet Kabel zu Router mit Internet
8. RTL-SDR mit RTL2832 Chip und R820T bzw. R820T2 Tuner – idealerweise mit einer kurzen USB Verlängerung

Für FM-Scans kann statt eines RTL-SDR ein TEF6686-Tuner verwendet werden. Das ist optional; ein RTL-SDR wird weiterhin unterstützt.
       
Hier eine komplette Amazon-Einkaufsliste inkl. optionaler Teile, aber ohne temporär benötigter Geräte:

https://amzn.to/2DtgQo8 

Alternativ auf https://www.amazon.de/ gehen und innerhalb des Menüs „Meine Listen“ den Punkt „Liste finden“ wählen und nach „fmlist“ suchen. 

:warning: Achtung: manche Teile sind zwecks Alternative oder für den Fall von Lieferengpässen auch mehrfach enthalten! Auch können einige Teile leider **nicht** außerhalb Deutschlands :de: verschickt werden.

<a id="section-3"></a>
# 3 Setup

<a id="section-3-1"></a>
## 3.1 Micro SD-Karte vorbereiten

Zunächst muss man mit dem PC bzw. Notebook ein Image mit dem Betriebssystem herunterladen. Abhängig vom Zeitaufwand, den man investieren will, muss man sich für ein Image entscheiden. Es gibt mittlerweile 64bit und 32bit Varianten von Raspberry OS:

https://www.raspberrypi.com/software/operating-systems/

Unterstützt und gestestet mit dem Scanner wurden Debian 13 (Trixie) und Debian 12 (Bookworm). Ältere Versionen, die auf Debian 9 (Strech) oder Debian 10 (Buster) oder Debian 11 (Bullseye) basieren, können zwar theoretisch noch verwendet werden, aber deren Support ist bereits vor einigen Jahren ausgelaufen.

Hinweis: Armbian wird wegen Probleme mit `sudo` nicht unterstützt.


https://de.wikipedia.org/wiki/Debian

Anschließend müssen die Schritte aus [Abschnitt 3.2.3 „Einrichtung vom Raspberry OS Image – FMLIST_Scan manuell installieren“](#section-3-2-3) und [Abschnitt 4.1 „Installation des Scanners“](#section-4-1) durchgeführt werden.

Wer nicht ganz so viel Zeit investieren will, kann für einen Raspberry Pi 3B oder 3B+ ein fertiges Image inklusive vorinstallierter Software und Scanner herunterladen. Es belegt entpackt ca. 6,5 GB Platz und basiert auf dem (älteren) Raspbian Image mit Desktop vom 13.11.2018:

https://drive.google.com/drive/folders/11NYMjgJuYaQGRc15-NkYrLblvWgHeep3?usp=sharing 

⚠️ Achtung: Dieses Image funktioniert (noch) nicht unter einem Raspberry 4, da es auf Stretch basiert und zum Beispiel der Bildschirm dunkel bleiben wird! Auch sind die Dateien veraltet, sodass es beim Installieren evtl. zu Problemen kommmen könnte!

:information_source: Hinweis: Mit diesem Image entfallen die [Abschnitte 3.2.2](#section-3-2-2) und [4.1](#section-4-1).

Während des Herunterladens und Schreibens des gewählten Images kann man schon mal mit dem Zusammenbau der Hardware (Raspberry-Pi Kühlkörper, Lüfter, ATX LEDs und Taster) beginnen. Siehe [Abschnitt 4.3 Anschluss von ATX-Tastern, LEDs und Piepser](#section-4-3).

Unter Windows benötigt man noch ein Programm, um das `.img.gz` komprimierte Image zu entpacken, z.B. mittels **7-zip**: http://www.7-zip.de/ . Nach Herunterladen des komprimierten Images und Installation von 7zip das Image entpacken.

Micro SD-Karte einlegen.

Zum Schreiben des Images auf die Micro SD-Karte, siehe Anleitung auf https://www.raspberrypi.org/documentation/installation/installing-images/README.md

Für Windows wird noch **Etcher** benötigt: https://www.balena.io/etcher/ . Etcher kann komprimierte Images (`.zip`, `.gz` und weitere) ohne vorheriges Entpacken auf die SD-Karte schreiben.

⚠️ Hier nun ganz vorsichtig nach Anleitung vorgehen! Es soll nicht das falsche Laufwerk überschrieben werden!

Falls der vorhandene Bildschirm nicht die benötigte hohe Auflösung verarbeitet – oder im Zweifel:

1. SD-Karte entfernen und erneut einlegen
2. NICHT formatieren!
3. das Laufwerk (Bootpartition) öffnen
4. die Datei `config.txt` mit einem Text-Editor öffnen
5. in der Zeile mit `hdmi_safe=1` das Lattenkreuz/die Raute `#` am Anfang der Zeile entfernen
6. Datei speichern, Editor schließen und SD-Karte sicher entfernen

Um gleich mit SSH arbeiten zu können:
    
Im Laufwerk eine leere Datei mit dem Namen `ssh` (ohne Endung) erzeugen. Ggf. Endung nachträglich entfernen. 

⚠️ ACHTUNG: Windows zeigt standardmäßig die Dateiendungen **nicht** an. Ggf. in der Windows-Eingabeaufforderung diese Befehle ausführen:
      
```
D:
```
Ggf. den Buchstaben ändern. Bedeutet: zu Laufwerk D: wechseln, der SD-Karte

```
type NUL >ssh
```
Hiermit eine leere “ssh” Datei erzeugen

```
dir
```
Nun erfolgt die Prüfung der Datei

```
exit
```
Eingabeaufforderung beenden

Damit der Raspberry sich von vornherein mit dem WLAN verbindet (zuvor den grauen Kasten für Gruppen-Einrichtungen im Kapitel 3.2 lesen!):

Im Laufwerk eine `wpa_supplicant.conf“` Datei erstellen. Mit dem Texteditor folgenden Inhalt eingeben:
      
```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=DE

network={
ssid="IHR_NETZWERK_NAME"
psk="IHR_NETZWERK_PASSWORT"
}
```

`gpio pwmTone 1 0`\t\t| Ton aus

<a id="section-3-2"></a>
## 3.2 Einrichtung des Raspberry OS Systems

<a id="section-3-2-1"></a>
### 3.2.1 Allgemein

Voreinstellung für beide Installationsvarianten (in den [Abschnitten 3.2.2](#section-3-2-2) und [3.2.3](#section-3-2-3)) sind:

Art|Code
--- | ---
Rechnername |	`raspberrypi`
Benutzername (username) | `pi`
Passwort | `raspberry`

Bei der Eingabe mit der manuellen Installation über [3.2.3](#section-3-2-3) ist darauf zu achten, dass noch das US :us:-Tastaturlayout vorliegt. Folglich sind <kbd>y</kbd> und <kbd>z</kbd> vertauscht!

<a id="section-3-2-2"></a>
### 3.2.2 Einrichtung mittels vorbereitetem FMLIST_SCAN Image

Das vorbereitete Image für einen Raspberry 3B+ und 3B (nicht 4B) kann unter folgendem Link heruntergeladen werden: https://drive.google.com/drive/folders/11NYMjgJuYaQGRc15-NkYrLblvWgHeep3?usp=sharing 

⚠️ Achtung: Das Passwort lautet für das Image vom 17.10.2019 jedoch `scanner123`

Es muss, wie im vorigen [Abschnitt 3.1 Micro SD-Karte vorbereiten](#section-3-1) beschrieben, auf die SD-Karte geschrieben werden.

Trotz der vorinstallierten Software sind noch weitere Schritte notwendig:

1. Passwort ändern, Rechner/Hostname anpassen;
z.B. in der GUI übers Hauptmenü (Himbeere ganz links oben), dann Preferences und „Raspberry Pi Configuration“.
2. Im Dialog der „Raspberry Pi Configuration“ kann man ggf. über die Deaktivierung der GUI sowie den Boot „To CLI“ nachdenken. Oder den automatischen Login deaktivieren
3. WLAN Einstellungen kann man auf verschiedene Weise vornehmen:
3.1 in der GUI rechts oben
3.2 Terminal / Xterm öffnen: dort `sudo raspi-config` und 2 Network Options und N2 Wi-fi wählen
3.3 Editieren der Datei mit `sudo nano /etc/wpa_supplicant/wpa_supplicant.conf`. Was man hier eintragen muss, ist beispielsweise in [Abschnitt 3.1 Micro SD-Karte vorbereiten](#section-3-1) zu finden.
4. Größe der Partition auf die ganze SD-Karte ausdehnen:
Terminal / Xterm öffnen: dort `sudo raspi-config` und dort `7 Advanced Options, A1 Expand Filesystem` wählen. Anschließend ist ein Reboot erforderlich.
5. Fmlist_scan Konfiguration anpassen;
siehe Ende von [Abschnitt 4.2 Konfiguration und automatische Aktivierung des Scanners](#section-4-2)

System updaten und anschließend neue Konfiguration durch Neustart in Betrieb nehmen:

```
sudo apt-get update && apt-get upgrade && reboot now
```

:warning: Beim aktuellen Image meldet `sudo apt-get upgrade` die Fehlermeldung mit 

> The following packages have unmet dependencies

mit `vlc-bin` und `E: Broken packages` am Ende. Die manuelle Installation von vlc-bin hilft:

```
sudo apt install vlc-bin
```

<a id="section-3-2-3"></a>
### 3.2.3 Einrichtung vom Raspberry OS Image – FMLIST_Scan manuell installieren

Nachdem die Micro SD-Karte mit dem Betriebssystem Raspberry OS vorbereitet ist, kann man das System erstmals starten:

1. Micro SD-Karte in den Raspberry Pi einlegen
2. ggf. Bildschirm über HDMI, USB-Tastatur, USB-Speicherstick und ggf. auch Ethernet anschließen
3. als Letztes die Stromversorgung anschließen (bitte nur empfohlene Netzteile verwenden!)

Bei Gruppen-Einrichtungen im gleichen Netzwerk / WLAN (zB bei einem Workshop) hätten alle Geräte denselben kollidierenden Rechnernamen! Daher sind alle Schritte bis inkl. der Anpassung des Rechnernamens einzeln durchzuführen. Also die Reihenfolge absprechen, anschließend `raspi-config` beenden und mit

```
sudo reboot now
```

den Raspberry herunterfahren, damit der nächste Teilnehmer loslegen kann. Alternativ bis zur Einrichtung des Rechnernamens inkl. Reboot direkt per Tastatur/Bildschirm konfigurieren.

Jetzt kann man den Bootvorgang des Raspberry OS Systems mit dem Hostnamen `raspberrypi` sehen, bis man zur Anmeldung gelangt.

1. Der Benutzername (username) lautet `pi`
2. Das Passwort lautet `raspberry`. Bei der Eingabe ist darauf zu achten, dass noch US-Tastaturlayout vorliegt. Folglich sind <kbd>y</kbd> und <kbd>z</kbd> vertauscht!
      
Hat man SSH aktiviert und Netzwerk angeschlossen bzw. WLAN richtig konfiguriert, so kann man sich per SSH / PuTTY verbinden. Für Anmeldung und Passwort-Eingabe sind die Tasten, wg. des Remote Zugriffs, nicht vertauscht. Von einem Linux aus gibt man einfach

```
ssh pi@raspberrypi
```

ein, um sich zu verbinden.

Für einen bequemen Zugriff von einem Windows-PC aus ist die Installation von Samba eine gute Möglichkeit. Samba kann eine Windows-kompatible Netzwerkfreigabe für Dateien auf dem Raspberry Pi bereitstellen. Die Installation ist optional; für gelegentliche Dateiübertragungen ist WinSCP einfacher.

Samba mit folgendem Befehl installieren:

```
sudo apt install samba
```

Nach der Installation die benötigte Freigabe in `/etc/samba/smb.conf` konfigurieren, mit `sudo smbpasswd -a pi` ein Samba-Passwort anlegen oder ändern und den Dienst mit `sudo systemctl restart smbd` neu starten. Nicht das gesamte System freigeben und Samba nicht direkt aus dem Internet erreichbar machen.

Anschließend sieht man die Eingabeaufforderung `$`. Hier kann man Kommandos eingeben. Das `$` zeigt an, dass man als „normaler“ Benutzer angemeldet ist.

Mit dem Kommando 

```
sudo
```

können einzelne Administrationskommandos gestartet werden, z.B. zur Installation von Software. Will man gleich mehrere Administrationskommandos eingeben, so startet man mit 

```
sudo bash
``` 

eine neue Eingabeaufforderung, die sich mit `#` meldet. Hier kann man die Administrationskommandos **ohne** zusätzliches `sudo` eingeben. Mit 

```
exit
```

beendet man die Eingabeaufforderung oder meldet sich vom System ab.

Im Folgenden deutet das `$` an, dass ein Kommando eingegeben werden soll. Das Zeichen `#` und der nachfolgende Text sind Kommentare, die beides nicht eingegeben werden dürfen und nur der besseren Übersicht angegeben werden.

Die Konfiguration startet mit

```
sudo raspi-config
```

Hinweis: im US-Tastaturlayout befindet sich <kbd>-</kbd> auf der <kbd>ß</kbd>-Taste

Es öffnet sich ein textbasiertes Menü:

1. Tastatur Layout einstellen – funktioniert nur wenn direkt angemeldet (ohne ssh):

```
4 Localisation Options → I3 Change Keyboard Layout → Generic 105 key (Intl) PC
→ Other → German → German (eliminate dead keys)
→ Enter (default für AltGr) → Enter (default für Compose key = No)
    • Passwort des Benutzers pi ändern:
1 Change User Password
    • Rechnername individualisieren:
2 Network Options → N1 Hostname → 
z.B. rpi001, rpi002 oder scanner001 oder beliebig selbst auswählen
Der Name sollte im eigenen Heim-Router auftauchen, so dass man sich die IP-Adresse(n)
– insbesondere für WLAN – aufschreiben kann. Ggf. kann man die IP-Adresse im Router fixieren, sodass diese sich nicht von alleine ändert.
    • ggf. WLAN einrichten – wenn noch nicht über wpa_supplicant.conf eingerichtet:
2 Network Options → N2 Wi-fi → DE → SSID → passphrase
    • Optional die Netzwerk Interface Bezeichnungen umstellen:
2 Network Options → N3 Network interface names → No
    • Zeitzone einstellen:
4 Localisation Options → I2 Change Timezone → None of the above → UTC
    • Sprachen einstellen:
4 Localisation Options → I1 Change Locale → alle de_DE_* sowie en_US_* sowie ggf. weitere auswählen und bestätigen. Anschließend den default setzen, z.B. „C.UTF-8“.
    • WLAN Region einstellen:
4 Localisation Options → I4 Change Wi-fi Country → DE Germany
    • SSH für Fernzugriff aktivieren – wenn noch nicht über die „ssh“ Datei konfiguriert:
5 Interfacing Options → P2 SSH → Yes (SSH server)
    • Grafikspeicher ggf. (wenn nicht benötigt) reduzieren, dass mehr für den Scanner verbleibt:
7 Advanced Options → A3 Memory split → 16
    • Audioausgabe immer über 3,5 mm Klinke, dass unabhängig von HDMI Nutzung:
7 Advanced Options → A4 Audio → 1 Force 3.5mm
    • System aktualisieren:
8 Update
    • Konfigurationsprogramm beenden
Finish → mit Tabulator Taste (links von Q) und Enter bestätigen
```

System updaten und anschließend neue Konfiguration durch Neustart in Betrieb nehmen:

```
sudo apt-get update && apt-get upgrade && reboot now
```

Aufgrund der Änderung des Rechnernamens muss die nächste Anmeldung per SSH/PuTTY entsprechend bestätigt werden.

Anschließend am Anmeldebildschirm mit dem neu vergebenem Passwort anmelden, ggf. Netzwerkkabel ziehen / entfernen und die IP-Adresse(n) prüfen:

```
ifconfig
```

Beim Router die IP-Adresse nachsehen und fixieren, sodass der Raspberry Pi immer dieselbe Adresse erhält.

Nun kann man sich lokal vom Raspberry Pi abmelden und per SSH oder PuTTY (Windows, http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html) anmelden. Dies funktioniert nur bei korrekter Konfiguration von SSID und Passphrase; ggf. die Konfiguration wiederholen.

Unter Windows sollte man auch noch **WinSCP** für den Dateitransfer installieren:	https://winscp.net/ . Für kabelgebundenen Zugang mit dem Notebook von unterwegs, siehe http://www.dhcpserver.de/cms/ . Zur Einrichtung mehrerer WLANs, siehe http://bit.ly/2xO4H7T (stackexchange.com).

<a id="section-4"></a>
# 4 Einrichtung des Scanners

<a id="section-4-1"></a>
## 4.1 Installation des Scanners

Dieser Abschnitt kann bei Verwendung / Nutzung des vorbereiteten Image für einen Raspberry 3B oder 3B+ laut [Abschnitt 3.2.2](#section-3-2-2) übersprungen werden.

Die folgenden Kommandos müssen in der Eingabeaufforderung (lokal oder SSH) des Raspberry Pi Systems eingegeben werden.

Der Scanner benötigt sudo-Rechte ohne Abfrage des Passworts. Für Raspberry OS ist dies bereits so eingestellt. Andere Betriebssysteme benötigen dies ggf. noch, falls `sudo bash` nach einem Passwort fragen sollte:

```
sudo nano /etc/sudoers.d/010_user-nopasswd
```

Der Dateiname `010_user-nopasswd` kann auf den Benutzernamen angepasst werden.

Im nano-Editor die folgende Zeile unter Anpassung des Benutzernamens user eintragen:

```
user ALL=(ALL) NOPASSWD:ALL
```

Anstelle von `user` den korrekten Benutzernamen verwenden! Datei Speichern und Editor schließen.

Zum Herunterladen des Scanners wird die Versionsverwaltung **git** benötigt. Die Installation erfolgt mit:

```
sudo apt install -y git
```

Nun als passender Benutzer – in der Regel `pi` – anmelden, unter dem auch der Scanner laufen soll.

Herunterladen des Scanner-Quellcodes:

```
git clone https://github.com/hayguen/fmlist_scan.git
cd fmlist_scan
```

In der Datei `setup.sh` können die wichtigsten Installationsparameter angepasst werden:

```
cat setup.sh
#export FMLIST_SCAN_USER="hayguen"	# default user "pi"
#export FMLIST_SCAN_RASPI="0"		# default "1" if Raspberry Pi hardware
```

In der Zeile mit `FMLIST_SCAN_USER` kann der Benutzername angepasst werden. Die Zeile mit `FMLIST_SCAN_RASPI` gibt an, dass es sich um eine Raspberry Pi Hardware handelt.

⚠️ Wichtig: Bei Anpassungen muss das Kommentarzeichen `#` am Beginn der Zeile entfernt werden.

```
nano setup.sh
```

Anschließend beginnt man (als Superuser) die Installation mit:

```
sudo ./setup.sh
```

Ggf. in einer zweiten ssh-Sitzung die Temperatur überwachen:

```
while true; do cat /sys/class/thermal/thermal_zone0/temp ; sleep 3 ; done
```

Dieser Schritt dauert eine Weile, da weitere Software fürs Raspberry OS System heruntergeladen und installiert wird. Des Weiteren werden auch einige Programme von github im Quellcode heruntergeladen, kompiliert (erstellt) und installiert. Man hat also genügend Zeit für einen Tee oder Kaffee ☕ :wink:

Nach der Installation sollte man sich die Konfigurationsdatei(en) ansehen:

Befehl | Erläuterung
--|--
`sudo nano /etc/fstab`	| Gerät für den USB-Speicherstick prüfen!
`crontab -e`			        | automatischer Start des Scanner bei @reboot<br>Hinweis: mit dem “#” kann auskommentiert werden


<a id="section-4-2"></a>
## 4.2 Konfiguration und automatische Aktivierung des Scanners

Die Konfiguration kann mit folgendem Kommando bearbeitet werden. 

ℹ️ Bei diesem Schritt am besten Zeit lassen und in Ruhe die Kommentare durchgehen!

```
nano ~/.config/fmlist_scan/config
```
      
Die Datei `~/.config/fmlist_scan/config` enthält die wichtigsten Scanner Einstellungen:

Einstellung | Hinweise
--|--
FMLIST_SCAN_DEAD_REBOOT | auf `1` umstellen, damit das System bei erkannten Fehlern automatisch neu gestartet wird
FMLIST_SCAN_AUTOSTART | legt fest, dass der Scanner automatisch mit dem System gestartet wird
FMLIST_SCAN_FM | legt fest, ob UKW/FM gescannt werden soll
FMLIST_SCAN_DAB | legt fest, ob DAB/DAB+ gescannt werden soll
FMLIST_SCAN_GPS_* | legt fest ob/wann der Scanner im stationären oder mobilen Modus arbeitet. Hier gibt man auch die stationären GPS Koordinaten vor.
FMLIST_SCAN_SAVE_PWMTONE | legt fest, ob mit dem angeschlossenem Piezo-Piepser bei Speicherung der Scan-Ergebnisse eine Tonfolge abgespielt werden soll
FMLIST_SCAN_SAVE_LEDPLAY | legt fest, ob mit den angeschlossenem LEDs bei Speicherung der Scan-Ergebnisse etwas umgeschaltet wird
FMLIST_SCAN_FOUND_PWMTONE | legt fest, ob mit dem angeschlossenen Piezo-Piepser mit jedem gefundenen Träger/Sender eine Tonfolge abgespielt werden soll
FMLIST_SCAN_FOUND_LEDPLAY | legt fest, ob mit den angeschlossenen LEDs mit jedem gefundenen Träger/Sender etwas umgeschaltet wird
FMLIST_SCAN_PWM_FEEDBACK | legt fest, ob mit dem angeschlossenen Piezo-Piepser mit jedem kompletten FM/DAB Scan der Erfolg mit einer Tonfolge abgespielt werden soll. Test/Probehören mit `scanToneFeedback.sh`:<br>FM Erfolg (mind. 1 Sender):		kurz kurz kurz<br>FM Misserfolg:			kurz kurz lang<br>DAB Erfolg (mind. 1 Sender):	kurz lang kurz<br>DAB Misserfolg:			kurz lang lang


Die Dateien `~/.config/fmlist_scan/fmscan.inc` und `~/.config/fmlist_scan/dabscan.inc` enthalten weitere Einstellungen, die insbesondere die Scan-Geschwindigkeit bzw. Gründlichkeit beeinflussen.

Abschließendes System-Update und Reboot mit:

```
sudo apt remove default-jre-headless openjdk-8-jre-headless:armhf
sudo apt remove ca-certificates-java
sudo apt-get update && apt-get upgrade && reboot now
```
      
Ggf. sollte – nach dem Reboot – noch eine Kalibrierung des RTL-SDR-Sticks durchgeführt werden:

```
kal.sh		
```
(Hinweis: der Hintergrund-Scan-Prozess muss beendet sein!)

<a id="section-4-2-1"></a>
### 4.2.1 TEF6686 und detaillierte DAB-Audioauswertung

Das TEF6686-FM-Backend kann eine serielle Verbindung oder eine Netzwerkverbindung verwenden. Für dessen Nutzung `FMLIST_FM_BACKEND=tef` setzen. Die wichtigsten Einstellungen sind `FMLIST_TEF_TRANSPORT`, `FMLIST_TEF_SERIAL_PORT`, `FMLIST_TEF_TCP_HOST` und `FMLIST_TEF_TCP_PORT`. Mit `FMLIST_TEF_TCP_HOST_AUTO=1` kann die automatische Suche nach einem TEF-Gerät im Netzwerk verwendet werden.

Im mobilen Modus verwendet der TEF6686 einen schnellen Suchlauf. Danach bleibt der Scanner länger auf den gefundenen Frequenzen, um RDS zu dekodieren. Im festen Modus kann der Scanner länger auf jeder Frequenz bleiben.

Der ABRA-DAB-Scanner kann Audio-Dienste genau prüfen. Dabei können Audio-Codec, Bitrate, Fehlerschutz, Sprache und Programmtyp ausgegeben werden. Schwache oder stumme Dienste werden als solche gemeldet und erhalten keine unsicheren Werte. Die genaue Auswertung dauert länger.

Für die DAB-Auswertung aus einer Aufnahme `FMLIST_SCAN_DAB_ANALYZE_FROM_RAW=1` setzen. Um FM und DAB gleichzeitig zu scannen, `FMLIST_SCAN_PARALLEL_FM_DAB=1` setzen. Dies wird für TEF-FM zusammen mit RTL-SDR-DAB unterstützt und ist standardmäßig aus. Bei einem Raspberry Pi mit wenig RAM `FMLIST_SCAN_DAB_RAW_PARALLEL_JOBS=1` beibehalten.

<a id="section-4-2-2"></a>
### 4.2.2 Webserver

Der Scanner enthält einen kleinen Webserver für das lokale Netzwerk. Er kann Scan-Ergebnisse anzeigen, den Scanner konfigurieren, WLAN einrichten und Tonfolgen testen.

Der Webserver wird bei der normalen Einrichtung standardmäßig installiert. Für eine separate Installation im Verzeichnis `src` ausführen:

```
sudo -E ./setup.sh wsrv
```

Der Webserver verwendet Port `8000`. Im Browser `http://<Raspberry-Pi-IP>:8000/` öffnen. Das anfängliche Passwort ist `scanner123`; es sollte sofort im Webinterface unter „Change Config Passphrase“ geändert werden.

Mit den folgenden Befehlen kann der Dienst geprüft oder neu gestartet werden:

```
sudo systemctl status scan-webserver.service
sudo systemctl restart scan-webserver.service
```

Der Webserver verwendet HTTP und ist für vertrauenswürdige lokale Netzwerke gedacht. Nicht direkt aus dem Internet erreichbar machen.

<a id="section-4-2-3"></a>
### 4.2.3 SideDoor-Fernzugriff

SideDoor baut einen umgekehrten SSH-Tunnel vom Raspberry Pi zum JumpServer des Projekts auf. Es ist optional und für Fernwartung oder Service-Zugriff vorgesehen.

Die JumpServer-Einstellungen und einen eindeutigen Gateway-Port zwischen `8000` und `8999` beim Administrator erfragen und anschließend `src/sidedoor_config` bearbeiten. Die Einrichtung im Verzeichnis `src` starten:

```
sudo -E ./setup_sidedoor <gateway-port>
```

Die Einrichtung installiert die benötigten Pakete, erzeugt die SSH-Schlüssel, richtet den dedizierten Service-Benutzer ein und aktiviert den systemd-Dienst `sidedoor`. Den öffentlichen Schlüssel `src/sidedoor-key/id_rsa.pub` auf Anfrage an den Administrator senden.

Den Tunnel mit `sudo systemctl status sidedoor` prüfen. SideDoor nur aktivieren, wenn der Fernzugriff mit dem Administrator abgestimmt ist.

<a id="section-4-3"></a>
## 4.3 Anschluss von ATX-Tastern, LEDs und Piepser

Der Raspberry Pi hat zwei Stiftleisten, die physikalisch beschriftet sind (oben Spalte “Physical”). In der Software **wiringPi** (http://wiringpi.com/, oben Spalte “wPi”) wird anders nummeriert.

Die rechte Spalte oben mit den physikalischen Pins 2, 4, 6, .., 40 ist an der Außenseite des Raspberry Pi. Pin 40 ist nahe der USB-Anschlüsse. Die linke Spalte mit den ungerade nummerierten Pins ist an der Innenseite des Raspberry Pi Boards.

Eine Übersicht aller Pins erhält man mit

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
### 4.3.1 Anschluss CPU-Lüfter

ℹ️ Abhängig vom Modell kann der Anschluss abweichen. Daher die Informationen des Herstellers beachten!

<a id="section-4-3-2"></a>
### 4.3.2 Anschluss Piezo-Piepser

Der Piepser wird an die physikalischen Pins 12 (+) und 14 (Masse/GND) angeschlossen. Test mit folgenden Befehlen

Befehl | Bedeutung
--| --
`gpio mode 1 pwm`		| physikalischer Pin 12 entspricht Pin 1 bei wiringPi
`gpio pwmTone 1 2000`	| Ton an
`gpio pwmTone 1 0`		| Ton aus

<a id="section-4-3-3"></a>
### 4.3.3 Anschluss ATX-Taster und LEDs

Der ATX-Taster zum Herunterfahren (shutdown) wird an die physikalischen Pins 39 und 40 angeschlossen. Test:

Befehle | Hinweise
--|--
`sudo systemctl stop gpio-input`		  | Dienst erst mal deaktivieren
`gpio mode 29 up`	                    | physikalischer Pin 40 entspricht Pin 29 bei wiringPi
`gpio read 29`		                    | muss 1 liefern wenn Taster nicht gedrückt,<br>muss 0 liefern wenn Taster gedrückt

Die grüne LED kommt an den physikalischen Pin 36 (wiringPi: 27), die Masse an Pin 34.
Die rote LED kommt an den physikalischen Pin 32 (wiringPi: 26), die Masse an Pin 30. Test:

Befehle | Hinweise
--|--
`gpio mode 27 output`	| wiringPi: 27 für grün, 26 für rot
`gpio write 27 on`		| jeweilige (hier: grüne) LED leuchtet
`gpio write 27 off`		| jeweilige LED erlischt

Nach den Tests der Taster den Dienst wieder reaktivieren:

```
sudo systemctl start gpio-input
```
![atx_schema](https://github.com/user-attachments/assets/d91d130c-ec5a-4a40-b80f-832eae80de3a)
![atx_foto](https://github.com/user-attachments/assets/f3651a06-0161-4a23-b909-9b80be5f4da1)


<a id="section-5"></a>
# 5. Betrieb des Scanners

<a id="section-5-1"></a>
## 5.1 Anmeldung / IP-Adresse

<a id="section-5-1-1"></a>
### 5.1.1 IP-Adresse

Versorgt man den Raspberry Pi mit Bildschirm und Tastatur, so kann man sich direkt anmelden. Hat man keine Anpassung an Rechnernamen und Passwort vorgenommen, so gelten die Zugangsdaten aus [Abschnitt 3.2.3](#section-3-2-3):

1. Der Benutzername (username) lautet `pi`
2. Das Passwort lautet `raspberry`. Bei der Eingabe ist darauf zu achten, ob noch US-Tastaturlayout vorliegt. In diesem Fall sind <kbd>y</kbd> und <kbd>z</kbd> sowie diverse Sonderzeichen vertauscht!

Nach der Anmeldung kann man sich mit dem Kommando `ipconfig` auch die IP-Adresse(n) ausgeben lassen.

Alternativ kann man den Raspberry Pi – ohne Bildschirm/Tastatur – anschließen und lässt den heimischen Router automatisch eine IP-Adresse zuweisen. Die vergebene IP-Adresse kann wahrscheinlich in der Router Konfiguration/Statusseite am PC nachgesehen werden. Abhängig vom Router sollte der Raspberry Pi am Hostnamen `raspberrypi` erkannt werden.

ℹ️ Hat man keinen Zugang zum Router, kann man am PC in der „DOS-Box“ mit dem Kommando

```
ping raspberrypi
```

die IP-Adresse ermitteln – wenn der Router DNS unterstützt. Falls man bei der Installation den Hostnamen bereits angepasst, so muss das ping Kommando entsprechend angepasst werden. Die DOS-Box wird unter Windows im Startmenü als „Eingabeaufforderung“ geführt.

Ohne DNS-Unterstützung des Routers muss man im Router Menü beobachten, welche IP-Adresse mit dem Start des Raspberry Pi neu dazu kommt. Stellt man fest, dass DNS funktioniert, so kann für SSH/SCP auch der Hostname verwendet werden.

<a id="section-5-1-2"></a>
### 5.1.2 Betriebs-Software für PC

Um den Raspberry Pi und Scanner vom PC aus zu steuern, ist Software für SSH und SCP notwendig. Ein Linux-PC bringt solche Software in der Regel bereits mit. Für Windows muss entsprechende Software ggf. nachinstalliert werden:

#### SSH für Remote Konsole: 
PuTTY http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html 

#### SCP für Dateitransfer: 
WinSCP https://winscp.net/ 
#### optional für kabelgebundenen Zugang mit dem Notebook von unterwegs: 
http://www.dhcpserver.de/cms/ 
#### Entpacker für komprimierte Scan-Ergebnisse
z.B. 7-zip: http://www.7-zip.de/ 
#### Betrachter für Scan-Ergebnisse im .csv Dateiformat
Zum einfachen Import ist LibreOffice / Calc empfohlen, welches einen einfachen Importdialog für Trennzeichen und Zeichenkodierung UTF-8 anzeigt: https://de.libreoffice.org/
#### Editor, z.B. für Konfigurationsdateien: 
Notepad++: https://notepad-plus-plus.org/ 

Für PuTTY und WinSCP wird empfohlen, diese über bzw. innerhalb des Softwarepakets PortableApps  https://portableapps.com/ zu installieren. Innerhalb von PortableApps steht auch diverse andere Software, wie z.B. TeamViewer,  zur Verfügung. Unabhängig von der portablen Nutzung auf einem USB-Speicherstick wird auch regelmäßig auf Updates geprüft.

ℹ️ Bei der Installation von PortableApps sind Pfade wie `C:\Programme` bzw. `C:\Programme (x86)` nicht empfehlenswert, da normale Benutzer keine Schreibrechte in diesen Pfaden haben.

Um Dateien direkt vom Explorer per Doppelklick oder „Öffnen mit“ nutzen zu können sollten **7zip**, **Notepad++** und **LibreOffice** direkt – ohne PortableApps – installiert werden.

<a id="section-5-1-3"></a>
### 5.1.3 Software für’s Android Smartphone

Für SSH kann die kostenlose App **ConnectBot** und **JuiceSSH** empfohlen werden, für Dateibearbeitung/-umbenennung die App **Total Commander**, für einen Bildschirmersatz (Anzeige erfolgt am Smartphone) **VNC Viewer** empfehlenswert.

<a id="section-5-2"></a>
## 5.2 Anpassung der Konfiguration / zusätzliches WLAN

Die Konfiguration des Scanners erfolgt in den Dateien aus dem Ordner `/home/pi/.config/fmlist_scan/`, u.a. config. Die Dateien können innerhalb einer SSH-Sitzung mit einem einfachen Editor wie z.B. `nano` oder `mcedit` bearbeitet werden. Bearbeitet man die Dateien vom PC aus, z.B. über **WinSCP**, so ist auf das korrekte Zeilenende-Verhalten (Unix: LF) zu achten! Als Editor für Windows wird **Notepad++** empfohlen.

Alternativ zur direkten Bearbeitung besteht nicht immer die Möglichkeit, sich über die IP-Zuordnung des heimischen Netzwerks anzumelden, z.B. in fremden Umgebungen. Bei ausgeschaltetem Raspberry Pi kann man den USB-Speicherstick abziehen und hierin Konfigurations-Anpassungen vornehmen: u.a. kann auch ein weiteres/zusätzliches WLAN eingerichtet werden.

Die Bearbeitung der Konfigurationsdateien kann von einem PC erfolgen. Mittels OTG-USB-Adapter ist es auch möglich, die Konfigurationsdateien mit einem Android-Smartphone zu bearbeiten:

![otg_adapter](https://github.com/user-attachments/assets/59116cda-022d-43d0-a39e-b8dc23a7a523)

Die Dateien aus dem Ordner `fmlist_scanner/config/` sind zu bearbeiten. Bei den Konfigurationsdateien ist der letzte benutzte Zustand enthalten. Ausnahme bildet die `wpa_supplicant.conf`, damit Fremde nicht durch Abziehen und Auslesen an die WLAN Passwörter gelangen können. Die Passwörter sind auch im Raspberry Pi gespeichert, so dass man durch komplette Entwendung an diese gelangen kann! Jedenfalls können neue zusätzliche WLANs eingetragen werden. Hierfür ist exakte SSID und der Schlüssel notwendig. In vielen Fällen stehen diese auf der Rückseite des Routers.

Die Bearbeitung am Smartphone ist im Vergleich zum PC nicht besonders komfortabel – aber auch mobil zu tätigen. Nach Bearbeitung der Datei(en) muss der Präfix `old_` aus dem Dateinamen jeder bearbeiten Datei entfernt werden:

![total_commander](https://github.com/user-attachments/assets/c729eaa7-349d-466b-8f2c-e859d1455c8c)

Nach ordnungsgemäßem Auswurf des USB-Speichers, Einstecken und Einschalten des Raspberry Pi wird die neue Konfiguration automatisch übernommen. Dies kann etwas dauern. Für WLAN sollte das LAN-Kabel von Anfang an **nicht** angeschlossen werden.

<a id="section-5-3"></a>
## 5.3 Statusmeldungen

Der Scanner meldet seinen Status primär über den Piezo-Piepser. An den Tonfolgen wird je Scan-Durchlauf die Erkennung von UKW/FM- sowie DAB-Sendern gemeldet. Siehe [Abschnitt 4.2](#section-4-2) für den Konfigurationseintrag `FMLIST_SCAN_PWM_FEEDBACK`:

Ereignis | Tonfolge 
-- | --
FM Erfolg (mind. 1 Sender)  |		kurz kurz kurz
FM Misserfolg |			kurz kurz lang
DAB Erfolg (mind. 1 Sender) |	kurz lang kurz
DAB Misserfolg |			kurz lang lang


Neben diesen Betriebs-Ergebnissen gibt es weitere Tonfolgen für

1. Start des Scanners
2. Fehlerzustand, z.B. kein RTL-Dongle gefunden
3. Scan-Ergebnisse gesichert

:information_source: Test/Probehören auch mit scanToneFeedback.sh (nach Anmeldung via SSH/PuTTY) möglich.

:information_source: Die einzelnen LED Farben haben keine dedizierte Bedeutung. Sie werden je erkannten Sender jeweils umgeschaltet. Es erfolgt keine Umschaltung, wenn der nächste Sender innerhalb einer Sekunde erkannt wird, um die Umschaltung zu limitieren.

<a id="section-5-4"></a>
## 5.4 ATX Taster

Es gibt zwei ATX Taster, falls diese mit angeschlossen wurden.

Der Taster, der näher an den USB Steckern angeschlossen ist, fährt den Raspberry Pi mit einmaligem Betätigen ordnungsgemäß herunter. Nach ca. 30 Sekunden kann der Strom abgezogen werden.

Der andere Taster stoppt ggf. den Scanner und lädt alle bisherigen Ergebnisse hoch – falls eine Internetverbindung besteht. Faktisch werden die zwei Kommandos aus dem folgenden [Abschnitt 5.6](#section-5-6) ausgeführt.

<a id="section-5-5"></a>
## 5.5 An der Kommandozeile (SSH oder lokal)

Befehl | Bedeutung
--|--
`screen -ls`	      			    | Anzeige der laufenden Hintergrundprozesse
`screen -r scanLoopBg`		    | zum Hintergrund-Scan-Prozess wechseln, <kbd>Ctrl</kbd>+<kbd>c</kbd> zum Beenden, <kbd>Ctrl</kbd>+<kbd>a</kbd> gefolgt von <kbd>d</kbd> wieder in den Hintergrund senden
`tail -f ~/ram/scanner.log`	  | Anzeige der Logs. Beenden mit <kbd>Ctrl</kbd>+<kbd>c</kbd>
`stopBgScanLoop.sh [wait]`		| ggf. laufenden Hintergrundprozess beenden<br>:information_source: Dies dauert → Prüfung mit `screen -ls`<br>alternativ Start mit `wait` - ohne die `[` `]`
`startBgScanLoop.sh`		    	| Scan-Prozess im Hintergrund starten
`cdResults`                  	| zu den gespeicherten Ergebnissen
`mc`					                | Midnight Commander zur Sichtung der Ergebnisse
`sudo shutdown now`			      | Herunterfahren – alternativ zum ATX-Taster<br>alternativ Strom ziehen, nach Gespeichert-Tonfolge
`monitorBgScanLoop.sh`	      | einfaches Skript zum Monitoren des Scanners
`checkScanConfig.sh`		      | prüfen der Konfiguration auf fehlende Einträge


`listDABaudio`              | DAB-Dienst, Ensemble, Codec, Bitrate und Audio-Details im aktuellen Ergebnisordner anzeigen
`listDABprogs`              | die gefundenen DAB-Dienste im aktuellen Ergebnisordner anzeigen
`listDABens`                | die gefundenen DAB-Ensembles im aktuellen Ergebnisordner anzeigen
`listDABch <channel>`       | Ergebnisse für einen DAB-Kanal anzeigen, zum Beispiel `listDABch 7D`
`listDABeid <eid>`          | Ergebnisse für eine Ensemble-ID anzeigen, zum Beispiel `listDABeid 1234`

Die Befehle mit `listDAB` sind einfache Kurzbefehle. Sie nach `cdResults` im Ergebnisverzeichnis ausführen, nachdem ein Scan CSV-Dateien erzeugt hat.

<a id="section-5-6"></a>
## 5.6 Ergebnisse

<a id="section-5-6-1"></a>
### 5.6.1 Aufbereitung und Upload

Ergebnisdateien werden im Betrieb unter `/mnt/sda1/fmlist_scanner` (mit der default Konfiguration von `FMLIST_SCAN_RESULT_DIR`) auf dem USB-Speicherstick abgelegt – jeweils in Unterordnern benannt nach Datum. Mit folgendem Kommando werden die Ergebnisse für den Upload aufbereitet:

```
prepareScanResultsForUpload.sh [all]
```

Ohne die optionale Angabe von `all` werden die die Ergebnisse bis auf den aktuellen Tag aufbereitet. Mit `all` dann wirklich alle Daten. Mit `all` sollte der Scanner vorher temporär deaktiviert werden. 

Die aufbereiteten Ergebnisse liegen anschließend unter `/mnt/sda1/fmlist_scanner/uploads`. Die bereits aufbereiteten Dateien werden in den Ordner `/mnt/sda1/fmlist_scanner/uploaded` verschoben.

Die Dateien können im Betrieb per scp bzw. WinSCP kopiert und anschließend gelöscht werden. 

Alternativ erfolgt die “Datenübertragung” über den USB-Speicherstick – nach Ausschalten des Systems. Der erneute Anschluss des USB-Speicherstick an den Raspberry Pi sollte vor Inbetriebnahme nicht vergessen werden.

Die aufbereiteten Ergebnisse werden mit folgendem Kommando hochgeladen:

```
uploadScanResults.sh
```
      
Bei Erfolg werden die Daten nicht gelöscht – sondern in einen anderen Ordner verschoben. Bei Misserfolg, z.B. wegen fehlender Internet Verbindung, bleiben die Daten im aufbereiteten Ordner.

Ein automatischer Upload der aufbereiteten Ergebnisse auf die FMList, z.B. per cronjob, erfolgt nicht. Den cronjob muss man manuell einrichten; z.B. mit `crontab -e` folgende Zeile hinzufügen:

```
15 0 * * * bash -l /home/pi/bin/prepareScanResultsForUpload.sh ; bash -l /home/pi/bin/uploadScanResults.sh
```

Hierbei ist zu beachten, dass alles in EINE Zeile kommt. Die nächste Version wird die Zeile bereits als Kommentar enthalten, dass man den Eintrag nur noch aktivieren muss. Die erste Zahl gibt die Minute an; die zweite die Stunde. Hier im Beispiel also 00:15 Uhr – nach UTC. Die Uhrzeit sollte angepasst werden. Ggf. die komplette Zeile duplizieren und unterschiedliche Zeiten angeben!

<a id="section-5-6-2"></a>
### 5.6.2 Online Auswertung

Online-Auswertungen gegen die FMList-Datenbank sind unter https://www.fmlist.org/ , nach Anmeldung unter dem Menüpunkt „URDS“, einsehbar. Der Menüpunkt URDS erscheint allerdings nur, wenn man die Zugriffsrechte hierfür hat. Ob und wie man die Zugriffsrechte erhält, ist mit Günter Lorenz <glorenz@fmlist.org> per E-Mail zu klären.

<a id="section-5-6-3"></a>
### 5.6.3 Manuelle Auswertung

Nach Aufbereitung der Daten (siehe [Abschnitt 5.6.1](#section-5-6-1)), Kopieren auf den PC (WinSCP) und Entpacken (7zip) kann die `*.csv` Datei mit einem Texteditor oder auch mit LibreOffice geöffnet werden. Bei letzterem erscheint ein Importdialog. Für korrekte Umlaute ist als Zeichensatz “Unicode (UTF-8)” einzustellen. Die restlichen Einstellungen passen normalerweise:

![text_import](https://github.com/user-attachments/assets/a2a84418-94da-4b65-b924-271ce7f1f6e0)

Die Datei wird ziemlich groß sein und hat auch sehr viele Spalten. Die Spaltenbeschriftungen fehlen, da sich diese je Gruppe (Gruppen-ID immer in Spalte 1) auch deutlich unterscheiden.

Die Datei ist eigentlich für die automatische Auswertung durch die FMList gedacht. Eine manuelle Sichtung war/ist nicht das Primärziel.

DAB Ensemble Einträge beginnen mit der Gruppen ID 20:

Die ersten Dutzend Spalten sind Uhrzeit und GPS Koordinaten. Der große Zahlenwert links ist die „UNIXTIME“ Angabe.

Code | Bedeutung
--|--
`UNIXTIME` |	Unix Zeitstempel in Sekunden seit 1.1.1970 00:00 UTC

Gefolgt von den GPS-Angaben:
   
Code | Bedeutung
--|--
`GPSLAT`| 	GPS Breitengrad
`GPSLON`| GPS Längengrad
`GPSMODE` |	GPS Mode ( Zustand: 2 = Lock ohne Höhe; 3 = Lock inkl. Höhe)
`GPSALT`|	GPS Höhe (bei GPSMODE 3)
`GPSTIME`|	GPS Uhrzeit in UTC

Für die hinteren Felder gibt es grobe Orientierungs-Marker "fic", "snr" und "tii". Die darauf folgenden Spalten sind dann in folgender jeweiliger Reihenfolge:

    • "fic", min_fic, max_fic, num_fic, avg_fic:
Diese fic Werte kommen aus der DAB-Dekodierung; und sind lediglich statistisch zusammengefasst. num_fic ist die Anzahl eingegangener fic Werte.

    • "snr", min_snr, max_snr, num_snr, avg_snr:
snr-Spalten "min_snr, max_snr, avg_snr" (ohne "snr, num_snr") sind in ganzen dB. Diese snr Werte kommen aus der DAB-Dekodierung. Die Zuverlässigkeit ist schwer zu beurteilen.
min ist der kleinste der eingegangenen Werte, max der größte, avg der arithmetische Mittelwert.

    • "tii", tii_id, num, max(avg_snr), max(min_snr), max(next_snr):
tii-Spalten "max(avg_snr), max(min_snr), max(next_snr)" (ohne "tii,tii_id,num") sind in 10tel dB. SNR (avg und min) bezieht sich allein auf die spektrale Leistung im Null-Symbol mit den TII-Trägern. Die angenommene TII-Trägerleistung wird im Verhältnis zu den schwächeren Rausch-"Trägern" betrachtet.
Anhand des dB-Werts sollte man "Phantom"-TIIs ausmustern können. Die Ausgabe ist bisher ungefiltert, um etwas Statistik zu sammeln - bevor man TIIs mit zu geringen Werten unterdrückt.
Next_SNR gibt den SNR-Abstand zur nächstbesten Main- oder Sub-ID an und stellt somit ein Maß für eine mögliche Verwechslung dar: Je kleiner next_snr, desto unsicherer.
Falls mehrere TIIs erkannt werden, folgen diese einfach nach einer Leerspalte.

Die Audio-Programme eines Ensembles werden in den Zeilen mit Gruppen ID 21 aufgeführt.

Die Daten-Programme beginnen mit Gruppen ID 22.


FM Sender mit RDS beginnen mit Gruppen ID 30:

Hier eine Beispiel-Zeile inkl. der Spalten-Kennungen:

```
30, 1560712920:UNIXTIME,freq,91400000, RDS:1, SNRmin:198, SNRmax:272,2019-06-16T19:22:00.046988951 Z:SYSTIME,48.885590906:GPSLAT,8.702782767:GPSLON,3:GPSMODE,293.611:GPSALT,2019-06-16T19:21:59.000Z:GPSTIME, PI:0xD30C, NPI:40, PS:" welle  ", NPS:3, TA:0, TP:1, MUSIC:1, PTY:"Pop music", GRP:"0A", STEREO:0, DYNPTY:1, OTHER_PI:, ,"allps:", "die neue"," welle  ",,
```

Alle dekodierten PS Einträge erfolgen nach der Spalte mit dem Inhalt „allps:“.

Code | Bedeutung
--|--
UNIXTIME|	Unix Zeitstempel in Sekunden seit 1.1.1970 00:00 UTC
SYSTIME|	Uhrzeit des Betriebssystems in UTC
GPSLAT|	GPS Breitengrad
GPSLON|	GPS Längengrad
GPSMODE|	GPS Mode (Zustand: 2 = Lock ohne Höhe; 3 = Lock inkl. Höhe)
GPSALT|	GPS Höhe (bei GPSMODE 3)
GPSTIME|	GPS Uhrzeit in UTC
RDS|		RDS vorhanden? (0 / 1)
SNRmin|	minSNR in Zehntel dB aus `checkSpectrumForCarrier` (preScan)
SNRmax|	maxSNR in Zehntel dB
PI|		PI Code
NPI |		wie oft dieser PI Code empfangen/dekodiert wurde
PS|	Program Station
NPS|		wie oft dieser PS empfangen/dekodiert wurde
TA|		Traffic Announcement (Verkehrsdurchsage aktiv)
TP|		Traffic Program (Verkehrsfunksender)
MUSIC|	Musikprogramm (im Gegensatz zu Sprachprogramm)
PTY|		Program Type
GRP|		RDS-Gruppen
STEREO | Stereo

Weitere FM-Sender ohne erfolgreiche RDS-Dekodierung beginnen mit Gruppen-ID 31.

<a id="section-5-7"></a>
## 5.7 Aufzeichnungen und Upload

Nach dem Stoppen des Scanners (`stopBgScanLoop.sh wait`, siehe [Abschnitt 5.5](#section-5-5)) können Signale manuell aufgezeichnet werden. Mit

```
recWFMchunk.sh <frequency in MHz> <duration in seconds> [<options to rtl_sdr>]
```
      
werden UKW/FM Aufzeichnungen getriggert. Die Aufzeichnung erfolgt sicherheitshalber zunächst im RAM (`/dev/shm/`) und wird anschließend auf den USB-Speicherstick kopiert sowie vom RAM gelöscht. Daher können  nicht beliebig lange Aufzeichnungen erstellt werden. Besonders interessant dürfte die Option `-g` für eine manuelle Gain- bzw. Verstärkung sowie die Option `-H` für das Wave-Dateiformat sein. Die Option `-H` muss direkt nach nach der Aufzeichnungsdauer angegeben werden, damit der Dateiname passend erzeugt wird. Mit dem Wave-Dateiformat kann die Datei, ohne zusätzlichen Import-Schritt, mit einer SDR-Software wie z.B. HDSDR direkt geöffnet werden. Bsp:

```
recWFMchunk.sh 100.7 20 -H -g 20.7
```
      
Welche Verstärkungswerte möglich sind, zeigt `rtl_test` an. Es muss mit <kbd>Ctrl</kbd> + <kbd>c</kbd> bzw. <kbd>Strg</kbd> + <kbd>c</kbd> abgebrochen werden.

Mit dem R820T(2) Tuner sind folgende Verstärkungswerte möglich:

Werte|Werte|Werte
--|--|-- 
 0.0 |  0.9 |  1.4	
 2.7 |  3.7 |  7.7	
 8.7 | 12.5	| 14.4	
15.7 | 16.6	| 19.7	
20.7 | 22.9	| 25.4	
28.0 | 29.7	| 32.8	
33.8 | 36.4 | 37.2	
38.6 | 40.2 | 42.1	
43.4 | 43.9 | 44.5	
48.0 | 49.6

:information_source: Mit anderen Werten in dB wird der naheliegendste Wert verwendet.

Ganz ähnlich zur Aufzeichnung von FM Kanälen werden auf DAB Kanäle komfortabel aufgezeichnet:

```
recDAB.sh <channel> <duration in seconds> [<options to rtl_sdr>]
```
      
Neben der Verstärkung des Tuners kann – falls vorhanden – die Bias-T-Spannung für einen passenden externen Vorverstärker bei einem V3-RTL-Dongle von rtl-sdr.com mit der Option `-O T=1` aktiviert werden. Konkret z. B.:

```
recDAB.sh 5C 4 -H -g 0.9 -O T=1
```
      
Die Aufzeichnungsmöglichkeit dient insbesondere für Test- und Prüfzwecke, z.B. Prüfung des AGC-Verhaltens auf Übersteuerung. Weiterhin kann man die Empfindlichkeit des Scanners mit anderer Software vergleichen. Eine erste Analyse kann für kurze Dateien (geringer Arbeitsspeicher) mit dem im Image vorinstallierten Audioeditor „Audacity“ erfolgen.

Der Dateiname der Aufzeichnung enthält automatisch alle relevanten Metadaten wie Frequenz/Kanal, Samplerate sowie GPS-Koordinaten. Der exakte Speicherort wird nach dem Umkopieren auf den USB-Speicherstick angezeigt.

Weiterhin können Testdaten dem Entwickler Hayati Aygün einfach bereitgestellt werden:

```
cd /mnt/sda1/fmlist_scanner/IQrecords/
uploadScanFilesToDeveloper.sh <target_foldername> <filenames>
```

Als Ordnername sollte eine Identifizierung/Kennung angegeben werden. Konkret z.B.

```
uploadScanFilesToDeveloper.sh HansMeier DAB-5C_2019-03-...
```

Hier sei noch auf die Tabulator-Taste <kbd>TAB</kbd>, bei deutscher Tastatur links von <kbd>Q</kbd>, zur Vervollständigung von Dateinamen hingewiesen. Alternativ kann die Shell (bash) auch mit `*` alle passenden Dateinamen ergänzen. Falls ihr auf diesem Wege Dateien bereitstellt, bitte per E-Mail melden, worum es sich handelt. Außerdem sollte ich euch zurückschreiben können ...

<a id="section-5-8"></a>
## 5.8 Probleme und mögliche Lösungen

### Es passiert einfach gar nichts

1. Stromversorgung prüfen. Mit anderem (USB-)Kabel testen.
2. SD-Karte entfernen und erneut einlegen

### Nach Einschalten piepst es einige Male (lang lang lang), die rote LED blinkt auf und alles wiederholt sich wieder

RTL-SDR aus- und wieder einstecken. Falls das Problem weiterhin besteht, Strom abziehen und wieder anschließen

### Raspberry Pi nach Betätigung des Reboot-Schalters nicht mehr erreichbar 

Manchmal bleibt das System beim Reboot hängen. Strom abziehen und neu anschließen

### Schlechte Empfangsqualität

1. Antennenanschluss und Stecker sowie Standort der Antenne prüfen!
2. Verstärkung richtig eingestellt?
3. Metallbedampfte Kfz-Fensterscheibe?

### Der Scanner friert nach einiger Zeit ein

1. offenbar ist der RTL-Dongle nicht besonders stabil
2. automatischen Reboot mit der Einstellung `FMLIST_SCAN_DEAD_REBOOT=“1“` in der Datei `/home/pi/.config/fmlist_scan/config` aktivieren. Ggf. auch die Einstellung `FMLIST_SCAN_DEAD_TIME` reduzieren, z.B. auf `240`.

### Sender werden nicht erkannt bzw. dekodiert. 

Hier kann es verschiedene Gründe geben. Die konkrete Ursache lässt sich am ehesten anhand einer Aufzeichnung beurteilen. Hierfür sind die Hilfsprogramme `recWFMchunk.sh` und `recDAB.sh` beigelegt/installiert. Hiermit bitte Aufzeichnungen von 10 – 30 Sekunden erstellen und bereitstellen.

### Der Piepser ist zu laut und nervt ggf. zu oft:

1. Per Konfiguration kann eingestellt werden, in welchen Fällen signalisiert wird. Die kann die Häufigkeit reduzieren – oder erhöhen.
2. Mit einem Klebeband kann die Öffnung des Piepsers teilweise oder ganz verklebt werden. Hier muss man bzgl. Lautstärke experimentieren.
3. Will man zeitweise gar nichts mehr hören, empfiehlt es sich, einen der 2 Pins einfach abzuziehen. Bei Wiederanbringung muss auf die Polung geachtet werden: (+) Symbol am Piezo.
	
### Nach Abziehen des LAN-Kabels friert auch die WLAN-SSH/PuTTY-Sitzung ein

Das ist bekannt. Für WLAN-Betrieb das LAN-Kabel nicht verwenden.

Für sonstige bzw. anhaltende Probleme bitte zuerst für die Mailing Liste https://groups.io/g/fmlist-scanner registrieren und anschließend Email an <fmlist-scanner@groups.io> senden.

Über diese Liste werden in Zukunft auch weitere Informationen über neue Versionen / Updates oder Fragen/Antworten eurerseits erfolgen. Über die Webseite zur Mailingliste sind auch weitere Fotos, Links und Wiki Seiten verfügbar.

