#!/usr/bin/env python3

# sudo systemctl status  scan-webserver.service
# sudo systemctl stop    scan-webserver.service
# sudo systemctl start   scan-webserver.service
# sudo systemctl restart scan-webserver.service

from http.server import HTTPServer, BaseHTTPRequestHandler
import ssl
import datetime as dt
from random import seed, random
import urllib
import subprocess
import os
import hashlib
from pathlib import Path

use_SSL = False   # False / True
SSL_key="/dev/shm/cert/rpi_scanner.key"
SSL_cert="/dev/shm/cert/rpi_scanner.crt"

# defaults for HOST_PORT: http: 80, https: 443, http proxy: 8080, https proxy: 4443
HOST_PORT = 8000
HOST_ADDRESS = ""
LOGIN_EXPIRATION_SECS = 60*10  # 10 min
VERBOSE_LOG = False


PWD_FILE = str(Path.home())+'/.config/fmlist_scan/web_password'
BIN_DIR = str(Path.home())+'/bin/'
print(f"password file: {PWD_FILE}")
try:
    with open(PWD_FILE, 'rb') as pwdf:
        CONFIG_PWD_STORAGE = pwdf.read(64)
        pwdf.close()
        CONFIG_PWD_SALT = CONFIG_PWD_STORAGE[:32]
        CONFIG_PWD_KEY  = CONFIG_PWD_STORAGE[32:]
except:
    print("Error reading password file. Using default password!")
    CONFIG_PWD = "scanner123"
    CONFIG_PWD_SALT = os.urandom(32)
    CONFIG_PWD_KEY = hashlib.pbkdf2_hmac( 'sha256',
        CONFIG_PWD.encode('utf-8'), # Convert the password to bytes
        CONFIG_PWD_SALT, 100000 )


#### session is key
# value is tuple of (logged :bool, last_IP :str, timeout :)
SESSIONS = dict()

eth0 = ("", "", "")
wifi = ("", "", "")
HOSTNAME = ""


def get_adapter_infos(adapter :str):
    MAC=""
    IP4=""
    IP6=""
    try:
        out = subprocess.check_output(f"ip a |grep -A 10 ': {adapter}: '", shell=True, universal_newlines=True, timeout=2)
    except:
        out = ""
        return (MAC, IP4, IP6)
    lno = 1
    for ln in str(out).split("\n"):
        if lno > 1 and len(ln)>1 and ln[0] != " ":  # got next adapter
            break
        words = ln.split()
        if 1 < len(words) and words[0] == "link/ether":
            MAC=words[1]
        if 1 < len(words) and words[0] == "inet":
            IP4=words[1]
            if len(IP4.split("/")) >= 2:
                IP4=IP4.split("/")[0]
        if 1 < len(words) and words[0] == "inet6":
            IP6=words[1]
            if len(IP6.split("/")) >= 2:
                IP6=IP6.split("/")[0]
        lno = lno +1
    return (MAC, IP4, IP6)


def run_and_get_output(prependBinDir, cmd, timeout_val_in_sec):
    cmdhtml = cmd.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\n","<br>")
    if prependBinDir:
        cmd_exec = BIN_DIR+cmd
    else:
        cmd_exec = cmd
    err_at_exec = False
    try:
        out = subprocess.check_output(cmd_exec, shell=True, universal_newlines=True, timeout=timeout_val_in_sec)
        outhtml = out.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\n","<br>")
        ret = f"<p>Output of {cmdhtml}:</p><p>{outhtml}</p>"
    except:
        err_at_exec = True
        ret = f"<p>Error executing {cmdhtml}!</p>"
    return (ret, err_at_exec)


def update_network_info():
    global eth0, wifi, HOSTNAME
    eth0 = get_adapter_infos("eth0")
    if VERBOSE_LOG:
        print(f"eth0:  MAC = '{eth0[0]}', IP4: '{eth0[1]}', IP6: '{eth0[2]}'")
    
    wifi = get_adapter_infos("wlan0")
    if VERBOSE_LOG:
        print(f"wlan0: MAC = '{wifi[0]}', IP4: '{wifi[1]}', IP6: '{wifi[2]}'")
    HOSTNAME = ""
    try:
        HOSTNAME = subprocess.check_output(f"hostname", shell=True, universal_newlines=True, timeout=2)
        if len(HOSTNAME.split("\n")) > 1:
            HOSTNAME = HOSTNAME.split("\n")[0]
    except:
        HOSTNAME = ""


def webhdr():
    update_network_info()
    global eth0, wifi, HOSTNAME
    r = '<table>\n'
    r = r + f'<tr><td>Host</td><td colspan="2">{HOSTNAME}</td></tr>\n'
    r = r + f'<tr><td>eth0</td><td>{eth0[1]}</td><td>{eth0[2]}</td></tr>\n'
    r = r + f'<tr><td>wlan0</td><td>{wifi[1]}</td><td>{wifi[2]}</td></tr>\n'
    r = r + '</table>\n'
    #r = f"Running on Host: '{HOSTNAME}'<br>"
    #r = r + f"eth0: IPv4 {eth0[1]} IPv6 {eth0[2]}<br>"
    #r = r + f"wlan0: IPv4 {wifi[1]} IPv6 {wifi[2]}<br>"
    return r


# value is tuple of (logged :bool, last_IP :str, timeout :)
def new_session(curr_IP : str):
    while True:
        session = str(int(random() * 65536))
        if not session in SESSIONS:
            SESSIONS[session] = (False, curr_IP, dt.datetime.now() )
            return session


def check_upd_session(session : str, curr_IP : str, pwd : str):
    present = dt.datetime.now()
    new_exp = present + dt.timedelta(0, LOGIN_EXPIRATION_SECS )

    delList=list()
    for s in SESSIONS:
        if SESSIONS[s][2] < present:
            delList.append(s)

    for s in delList:
        v = SESSIONS[s]
        if VERBOSE_LOG:
            print(f"removing expired session {s}: {v}")
        del SESSIONS[s]

    if session is None or len(session) <= 0:
        session = new_session(curr_IP)
        if VERBOSE_LOG:
            print(f"created new session '{session}' : was empty")

    if session in SESSIONS:
        v = SESSIONS[session]
        if v[1] != curr_IP:
            session = new_session(curr_IP)
            if VERBOSE_LOG:
                print(f"created new session '{session}' : IP mismatch")
        elif v[2] < present:
            SESSIONS[session] = (False, curr_IP, new_exp )
            if VERBOSE_LOG:
                print(f"session '{session}' expired: logged off")
    else:
        SESSIONS[session] = (False, curr_IP, new_exp)
        if VERBOSE_LOG:
            print(f"created non existing session '{session}'")

    # always update expiration
    v = SESSIONS[session]
    new_pwd_key = hashlib.pbkdf2_hmac(
        'sha256', pwd.encode('utf-8'), CONFIG_PWD_SALT, 100000 )
    if not v[0] and new_pwd_key == CONFIG_PWD_KEY:
        v = ( True, curr_IP, new_exp )
        if VERBOSE_LOG:
            print("login successful")
    else:
        v = ( v[0], curr_IP, new_exp )
    SESSIONS[session] = v
    return session


def procSessionFromContentPOSTfields(inp):
    x = inp.decode('utf-8').split('&')
    d = dict()
    for v in x:
        kv = v.split("=")
        if len(kv) == 2:
            k = kv[0]
            v = urllib.parse.unquote_plus(kv[1])
            #print(f"  key '{k}'  value '{v}'")
            d[k] = v
    #print("-------------------------------")
    return d


def splitURL(inp : str):
    lx = inp.split('?')
    if len(lx) >= 2:
        sx = '?'.join(lx[1:len(lx)])
    else:
        sx = ""
    p = lx[0]
    if len(p) > 0 and p[-1] == "/":
        p = p[0:-1]
    return (p, sx)


def joinURL(p, g):
    if len(g) > 0:
        return p + "?" + g
    else:
        return p


def procSessionFromPathGETfields(inp : str, curr_IP : str, fields : dict):
    #print(f"inp type for procSessionFromPathGETfields(): {type(inp)}")
    #print(f"ip_addr type for procSessionFromPathGETfields(): {type(inp)}")
    (p, sx) = splitURL(inp)

    x = sx.split('&')
    #print(f"after split(&): {type(x)} {len(x)}: {x}")
    d = fields   # start with POST fields, overwrite with GET fields
    for v in x:
        kv = v.split("=")
        if len(kv) == 2:
            k = kv[0]
            v = urllib.parse.unquote_plus(kv[1])
            #print(f"  key '{k}'  value '{v}'")
            d[k] = v
    #print("-------------------------------")
    p = ""
    if "pwd" in d:
        p = d["pwd"]
    prev_session = ""
    if "session" in d:
        prev_session = d["session"]
        new_session = check_upd_session(prev_session, curr_IP, p)
    else:
        new_session = check_upd_session(None, curr_IP, p)
    d["session"] = new_session
    return ( d, prev_session != new_session )

update_network_info()
print(f"start service at port {HOST_PORT} @ {HOSTNAME}")
seed()   # int(dt.datetime.now().timestamp()))


def HEADstr(t : str):
    #stylehdr = b'<head><meta http-equiv="refresh" content="0"/><style>p, button {font-size: 1em}</style><style>table, th, td {border: 1px solid black;}</style></head>'
    stylehdr = b'<head><style>p, button {font-size: 1em}</style><style>table, th, td {border: 1px solid black;}</style>'

    if len(t) > 0:
        x = stylehdr + str.encode(t) + b'</head>'
    else:
        x = stylehdr + b'</head>'
    if VERBOSE_LOG:
        print(f"headstr: {x}")
    return x


class RequestHandler(BaseHTTPRequestHandler):

    def send_response(self, code, message=None):
        """ override to customize header """
        self.log_request(code)
        self.send_response_only(code)
        self.send_header('Server','python3 httpserver for FMLIST-scanner ')
        self.send_header('Date', self.date_time_string())
        self.end_headers()

    def get_fields(self, withPOST : bool):
        if withPOST:
            clen = self.headers['Content-Length']
            if clen is not None and len(clen) > 0:
                content_length = int(self.headers['Content-Length'])
                x = self.rfile.read(content_length)
                d = procSessionFromContentPOSTfields(x)
            else:
                d = procSessionFromContentPOSTfields(b'')
        else:
            d = dict()
        dc = procSessionFromPathGETfields( self.path, self.client_address[0], d )
        return dc

    def create_html_form_str(self, f, t, session ):
        s = f'<form action="/{f}?session={session}" method="POST" enctype="application/x-www-form-urlencoded">'
        s = s + f'<input type="hidden" id="action" name="action" value="{f}">'
        s = s + f'<button style="color:blue">{t}</button>'
        s = s + '</form>'
        return s

    def create_html_form(self, f, t, session ):
        self.wfile.write(str.encode( self.create_html_form_str(f, t, session) ))

    def do_GET(self):
        """ response for a GET request """
        if self.path == "/favicon.ico":
            self.send_response(404)
            return
        (d, session_changed) = self.get_fields(False)
        if VERBOSE_LOG:
            print(f"d: {d}")
            print(f"GET fields session changed {session_changed}")
        session=d["session"]
        sv = SESSIONS[session]
        loggedIn = sv[0]
        (ps, gps) = splitURL(self.path)
        reloadURL = joinURL(ps, f"session={session}")

        self.send_response(200)
        if session_changed:
            if VERBOSE_LOG:
                print(f"reload {reloadURL} in 1 sec .. (ps='{ps}', session={session}")
            self.wfile.write( HEADstr( f'<meta http-equiv="refresh" content="1; url={reloadURL}">') )
        elif ps=="/status":
            self.wfile.write( HEADstr( f'<meta http-equiv="refresh" content="3; url={reloadURL}">') )
        else:
            self.wfile.write( HEADstr("") )

        self.wfile.write(b'<body>')
        if VERBOSE_LOG:
            self.wfile.write(str.encode( f"<p>requested URL path: '{self.path}'</p>"))
            self.wfile.write(str.encode( f"<p>Your session '{session}: successful login {loggedIn}: {sv}'</p>"))
            self.wfile.write(str.encode( f"<p>Your IP:port {self.client_address[0]}:{self.client_address[1]}</p>"))
            print(f"\nrequested URL: {self.path}")
            print(f"requested URL path part: {ps}")
            print(f"requested URL get part:  {gps}")

        if not loggedIn:
            if ps=="/status":
                self.wfile.write(str.encode( webhdr() ))
                self.wfile.write(str.encode("<hr>"))
                out_html, err_at_exec = run_and_get_output(True, "statusBgScanLoop.sh", 3)
                self.wfile.write(str.encode(out_html))
                self.wfile.write(str.encode("<hr>"))
                self.wfile.write(str.encode(f'<p><a href="/status?session={session}">Reload/Update Scanner Status</a> every 3 seconds ..</p>'))
            else:
                self.wfile.write(f'<h1>Login required</h1>'.encode())
                self.wfile.write(f'<form action="?session={session}" method="POST" enctype="application/x-www-form-urlencoded">'.encode())
                self.wfile.write(b'<span>Config password:</span>')
                self.wfile.write(b'<input type="password" id="pwd" name="pwd">')
                self.wfile.write(f'<input type="hidden" id="action" name="action" value="login">'.encode())
                self.wfile.write(f'<input type="hidden" id="session" name="session" value="{session}">'.encode())
                self.wfile.write(b'<button style="color:blue">Submit</button>')
                self.wfile.write(b'</form>')
                self.wfile.write(str.encode( f'<br><p>without login, only <a href="/status?session={session}">Show Scanner Status</a> is available</p>'))

        else:
            if ps=="/wifi":
                self.wfile.write(f'<h1>WiFi configuration</h1>'.encode())
                self.wfile.write(f'<form action="/wifi?session={session}" method="POST" enctype="application/x-www-form-urlencoded">'.encode())
                self.wfile.write(b'<span>Wifi SSID:</span>')
                self.wfile.write(f'<input type="hidden" id="action" name="action" value="wifi">'.encode())
                self.wfile.write(f'<input type="text" id="ssid" name="ssid">'.encode())
                self.wfile.write(b'<br><span>WPA/2 passphrase:</span>')
                self.wfile.write(b'<input type="password" id="pwd" name="pwd">')
                self.wfile.write(b'<button style="color:blue">Submit</button>')
                self.wfile.write(b'</form>')

            elif ps=="/wifi_reset":
                self.wfile.write(f'<h1>RESET ALL WiFi CONFIG</h1>'.encode())
                self.create_html_form("wifi_reset", "RESET CONFIG", session )

            elif ps=="/status":
                self.wfile.write(str.encode( webhdr() ))
                self.wfile.write(str.encode("<hr>"))
                out_html, err_at_exec = run_and_get_output(True, "statusBgScanLoop.sh", 3)
                self.wfile.write(str.encode(out_html))
                self.wfile.write(str.encode("<hr>"))
                self.wfile.write(str.encode(f'<br><p><a href="/status?session={session}">Reload/Update Scanner Status</a> every 3 seconds ..</p>'))

            elif ps=="/reboot":
                self.wfile.write(f'<h1>Reboot Machine?</h1>'.encode())
                self.create_html_form("reboot", "REBOOT", session )

            elif ps=="/shutdown":
                self.wfile.write(f'<h1>Shutdown Machine?</h1>'.encode())
                self.create_html_form("shutdown", "SHUTDOWN", session )

            elif ps=="/config_pwd":
                self.wfile.write(f'<h1>Change Config Passphrase</h1>'.encode())
                self.wfile.write(f'<form action="/config_pwd?session={session}" method="POST" enctype="application/x-www-form-urlencoded">'.encode())
                self.wfile.write(b'<span>Old passphrase:</span>')
                self.wfile.write(f'<input type="password" id="old_pwd" name="old_pwd">'.encode())
                self.wfile.write(b'<br><span>New passphrase:</span>')
                self.wfile.write(b'<input type="password" id="new_pwd" name="new_pwd">')
                self.wfile.write(f'<input type="hidden" id="action" name="action" value="config_pwd">'.encode())
                self.wfile.write(b'<button style="color:blue">Submit</button>')
                self.wfile.write(b'</form>')

            else:
                self.wfile.write(f'<h1>FMLIST-Scanner Menu</h1>'.encode())

                if False:
                    self.wfile.write(str.encode( f'<p><a href="/status?session={session}">Show Scanner Status</a></p>'))
                    self.wfile.write(str.encode( f'<p><a href="/wifi?session={session}">Add WiFi Config</a></p>'))
                    self.wfile.write(str.encode( f'<p><a href="/wifi_reset?session={session}">Reset All WiFi Config</a></p>'))
                    self.create_html_form("wifi_reconfig", "Reconfigure WiFi", session )
                    self.create_html_form("start_scanner", "Start Scanner", session )
                    self.create_html_form("stop_scanner", "Stop Scanner", session )
                    self.create_html_form("prepare_upload_all", "Prepare All &amp; Upload", session )
                    self.create_html_form("upload_results", "Upload Results", session )
                    self.wfile.write(str.encode( f'<p><a href="/reboot?session={session}">Reboot Machine</a></p>'))
                    self.wfile.write(str.encode( f'<p><a href="/shutdown?session={session}">Shutdown Machine</a></p>'))
                    self.wfile.write(str.encode( f'<p><a href="/config_pwd?session={session}">Change Config Passphrase</a></p>'))
                else:
                    r = '<table>\n'
                    r = r + f'<tr><td colspan="2"><p><a href="/status?session={session}">Show Scanner Status</a></p><br>' + '</td></tr>\n'
                    r = r + '<tr><td>' + f'<p><a href="/wifi?session={session}">Add WiFi Config</a></p><br>' + '</td>\n'
                    r = r + '<td>' + f'<p><a href="/wifi_reset?session={session}">Reset All WiFi Config</a></p><br>' + '</td></tr>\n'
                    r = r + '<tr><td colspan="2">' + self.create_html_form_str("wifi_reconfig", "Reconfigure WiFi", session ) + '</td></tr>\n'
                    r = r + '<tr><td>' + self.create_html_form_str("start_scanner", "Start Scanner", session ) + '</td>\n'
                    r = r + '<td>' + self.create_html_form_str("stop_scanner", "Stop Scanner", session ) + '</td></tr>\n'
                    r = r + '<tr><td>' + self.create_html_form_str("prepare_upload_all", "Prepare All &amp; Upload", session ) + '</td>\n'
                    r = r + '<td>' + self.create_html_form_str("upload_results", "Upload Results", session ) + '</td></tr>\n'
                    r = r + '<tr><td>' + f'<p><a href="/reboot?session={session}">Reboot Machine</a></p><br>' + '</td>\n'
                    r = r + '<td>' + f'<p><a href="/shutdown?session={session}">Shutdown Machine</a></p><br>' + '</td></tr>\n'
                    r = r + '<tr><td colspan="2">' + f'<p><a href="/config_pwd?session={session}">Change Config Passphrase</a></p><br>' + '</td></tr>\n'
                    r = r + '<tr><td colspan="2">' + self.create_html_form_str("logout", "Logout", session ) + f'expiration is at {SESSIONS[session][2]}<br>current date/time: {dt.datetime.now()}' + '</td></tr>\n'
                    r = r + '</table>'
                    self.wfile.write(str.encode(r))

        self.wfile.write(str.encode( f'<p>back to <a href="/?session={session}">menu</a></p>'))
        self.wfile.write(str.encode( f'<p>to <a href="https://groups.io/g/fmlist-scanner" target="_groups_io">Mailing List and Group at groups.io</a></p>'))
        self.wfile.write(str.encode( f'<p>to <a href="https://www.fmlist.org/" target="_fmlist_org">FMLIST.org</a>. look for the URDS menu.</p>'))
        self.wfile.write(b'</body>')

    def do_POST(self):
        """ response for a POST """
        (d, session_changed) = self.get_fields(True)
        if VERBOSE_LOG:
            print(f"d: {d}")
            print(f"GET fields session changed {session_changed}")
        session=d["session"]
        sv = SESSIONS[session]
        loggedIn = sv[0]
        (ps, gps) = splitURL(self.path)
        reloadURL = ""
        reloadTim = 2

        if not loggedIn:
            out_html = "<p>Error: You are (no longer) logged in for this operation!</p>"
            reloadURL = "/"

        elif ps=="/wifi":
            out_html, err_at_exec = run_and_get_output(True, "scannerPrepareWifiConfig.sh", 3)

            if not err_at_exec:
                try:
                    with open("/dev/shm/wpa_supplicant/wpa_supplicant.conf", "a") as wpafile:
                        wpafile.write('\n\nnetwork={\n')
                        wpafile.write('  ssid="{}"\n'.format(d["ssid"]))
                        wpafile.write('  psk="{}"\n'.format(d["pwd"]))
                        wpafile.write('}\n\n')
                        wpafile.close()
                except:
                    err_at_exec = True
                    out_html = f"<p>Error appending SSID/passphrase to /dev/shm/wpa_supplicant/wpa_supplicant.conf after scannerPrepareWifiConfig.sh!</p>"

            if not err_at_exec:
                out_html, err_at_exec = run_and_get_output(True, "scannerFinalizeWifiConfig.sh", 3)

        elif ps=="/wifi_reset":
            out_html, err_at_exec = run_and_get_output(True, "scannerResetWifiConfig.sh", 3)

        elif ps=="/wifi_reconfig":
            # "wpa_cli" requires "sudo apt install wpasupplicant"
            out_html, err_at_exec = run_and_get_output(True, "scannerReconfigWifi.sh", 10)

        elif ps=="/start_scanner":
            out_html, err_at_exec = run_and_get_output(True, "startBgScanLoop.sh", 5)

        elif ps=="/stop_scanner":
            out_html, err_at_exec = run_and_get_output(True, "stopBgScanLoop.sh", 5)

        elif ps=="/prepare_upload_all":
            out_html, err_at_exec = run_and_get_output(False, f"( {BIN_DIR}prepareScanResultsForUpload.sh all ; {BIN_DIR}uploadScanResults.sh ) &", 5)
            #out_html, err_at_exec = run_and_get_output(False, f'bash -c "sleep 5 ; {BIN_DIR}uploadScanResults.sh" &', 2)

        elif ps=="/upload_results":
            out_html, err_at_exec = run_and_get_output(True, "uploadScanResults.sh", 10)

        elif ps=="/reboot":
            out_html, err_at_exec = run_and_get_output(True, "stopBgScanLoop.sh", 5)
            out_html, err_at_exec = run_and_get_output(False, 'sudo shutdown -r +1 "reboot from local web control"', 5)

        elif ps=="/shutdown":
            out_html, err_at_exec = run_and_get_output(True, "stopBgScanLoop.sh", 5)
            out_html, err_at_exec = run_and_get_output(False, 'sudo shutdown -p +1 "poweroff from local web control"', 5)

        elif ps=="/config_pwd":
            global CONFIG_PWD_SALT, CONFIG_PWD_KEY
            config_pwd_status = ""
            old_pwd_key = hashlib.pbkdf2_hmac(
                'sha256', d["old_pwd"].encode('utf-8'), CONFIG_PWD_SALT, 100000 )
            if not CONFIG_PWD_KEY == old_pwd_key:
                out_html = "<p>Error: old passphrase does not match!</p>"
                err_at_exec = True
            elif len(d["new_pwd"].rstrip()) < 4:
                out_html = "<p>Error: new passphrase too short. minimum 4 characters required!</p>"
                err_at_exec = True
            else:
                NEW_CONFIG_PWD_SALT = os.urandom(32)
                NEW_CONFIG_PWD_KEY = hashlib.pbkdf2_hmac( 'sha256',
                    d["new_pwd"].rstrip().encode('utf-8'), # Convert the password to bytes
                    NEW_CONFIG_PWD_SALT, 100000 )
                NEW_CONFIG_PWD_STORAGE = NEW_CONFIG_PWD_SALT + NEW_CONFIG_PWD_KEY
                try:
                    with open(PWD_FILE, "wb") as pwdf:
                        pwdf.write(NEW_CONFIG_PWD_STORAGE)
                        pwdf.close()
                    CONFIG_PWD_SALT = NEW_CONFIG_PWD_SALT
                    CONFIG_PWD_KEY = NEW_CONFIG_PWD_KEY
                    out_html = "<p>Saved new passphrase.</p>"
                    err_at_exec = False
                except:
                    out_html = "<p>Error saving new passphrase!</p>"
                    err_at_exec = True
                try:
                    pwdfc = Path(PWD_FILE)
                    pwdfc.chmod(0o600)   # read/write only for owner - nobody else
                except:
                    out_html = out_html + "<p>Error changing permissions for password file!</p>"
                    err_at_exec = True

        elif ps=="/logout":
            if loggedIn:
                del SESSIONS[session]
                out_html = "<p>Logout successful.</p>"
            else:
                out_html = "<p>Error: You were not logged in.</p>"

        else:
            err_at_exec = False
            reloadURL = joinURL(ps, f"session={session}")

        self.send_response(200)
        if len(reloadURL) > 0:
            self.wfile.write( HEADstr(f'<meta http-equiv="refresh" content="{reloadTim}; url={reloadURL}">') )
        else:
            self.wfile.write( HEADstr('') )

        self.wfile.write(b'<body>')
        self.wfile.write(str.encode( webhdr() ))

        if VERBOSE_LOG:
            self.wfile.write(str.encode( f"<p>requested POST URL path: '{self.path}'</p>"))
            self.wfile.write(str.encode( f"<p>Your session '{session}: successful login {loggedIn}: {sv}'</p>"))
            self.wfile.write(str.encode( f"<p>Your IP:port {self.client_address[0]}:{self.client_address[1]}</p>"))
            print(f"\nrequested URL: {self.path}")
            print(f"requested URL path part: {ps}")
            print(f"requested URL get part:  {gps}")

        self.wfile.write('<hr>'.encode())
        self.wfile.write(str.encode( f'<p>POST for action=&quot;{d["action"]}&quot;</p>' ))

        self.wfile.write('<hr>'.encode())

        if not loggedIn:
            self.wfile.write(str.encode(out_html))
        elif ps=="/wifi":
            self.wfile.write(str.encode(out_html))
        elif ps=="/wifi_reset":
            self.wfile.write(str.encode(out_html))
        elif os=="/wifi_reconfig":
            self.wfile.write(str.encode(out_html))
        elif ps=="/start_scanner":
            self.wfile.write(str.encode(out_html))
        elif ps=="/stop_scanner":
            self.wfile.write(str.encode("<p>Stopping scanner might take up to a minute.</p>"))
            self.wfile.write(str.encode(out_html))
        elif ps=="/prepare_upload_all":
            self.wfile.write(str.encode("<p>Uploads are processed every 10 minutes - except between 0:00 and 4:00 CET!</p>"))
            self.wfile.write(str.encode(out_html))
        elif ps=="/upload_results":
            self.wfile.write(str.encode(out_html))
        elif ps=="/reboot":
            self.wfile.write(str.encode("<p>REBOOT in 1 minute.</p>"))
            self.wfile.write(str.encode(out_html))
        elif ps=="/shutdown":
            self.wfile.write(str.encode( f"<p>POWER OFF in 1 minute.</p>"))
            self.wfile.write(str.encode(out_html))
        elif ps=="/config_pwd":
            self.wfile.write(str.encode(out_html))
        elif ps=="/logout":
            self.wfile.write(str.encode(out_html))
        else:
            #self.wfile.write(str.encode( f"<p>Unknown URL path '{ps}'!</p>"))
            pass

        self.wfile.write('<hr>'.encode())
        # self.wfile.write(str.encode( f'<p>will reload site with GET, to get rid of POST parameters, in few seconds ..</p>'))
        self.wfile.write(str.encode( f'<p>back to <a href="/?session={session}">menu</a></p>'))

        self.wfile.write(b'</body>')


def run(server_class=HTTPServer, handler_class=BaseHTTPRequestHandler):
    """ follows example shown on docs.python.org """
    server_address = (HOST_ADDRESS, HOST_PORT)
    httpd = server_class(server_address, handler_class)
    if use_SSL:
        httpd.socket = ssl.wrap_socket (httpd.socket, SSL_key, SSL_cert, server_side=True)
    httpd.serve_forever()

if __name__ == '__main__':
    run(handler_class=RequestHandler)


