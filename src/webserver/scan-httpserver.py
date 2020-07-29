#!/usr/bin/env python3

from http.server import HTTPServer, BaseHTTPRequestHandler
import ssl
import datetime as dt
from random import seed, random
import urllib
import subprocess
import os
from pathlib import Path

import get_adapter_infos as ai

use_SSL = False   # False / True
SSL_key="/dev/shm/cert/rpi_scanner.key"
SSL_cert="/dev/shm/cert/rpi_scanner.crt"

# defaults for HOST_PORT: http: 80, https: 443, http proxy: 8080, https proxy: 4443
HOST_PORT = 8000
HOST_ADDRESS = ""
LOGIN_EXPIRATION_SECS = 60

PWD_FILE = str(Path.home())+'/.config/fmlist_scan/web_password'
BIN_DIR = str(Path.home())+'/bin/'
print(f"password file: {PWD_FILE}")
try:
    with open(PWD_FILE, 'r') as pwdf:
        CONFIG_PWD = pwdf.readlines()[0].rstrip()
        pwdf.close()
    #print(f"CONFIG_PWD: '{CONFIG_PWD}'")
except:
    print("error reading password file or extracting 1st line! Using default password!")
    CONFIG_PWD = "scanner123"

if len(CONFIG_PWD.replace("\n", "")) <= 0:
    print("password is empty!? Using default password!")
    CONFIG_PWD = "scanner123"


#### session is key
# value is tuple of (logged :bool, last_IP :str, timeout :)
SESSIONS = dict()

VERBOSE_LOG = False

eth0 = ai.get_adapter_infos("eth0")
if VERBOSE_LOG:
    print(f"eth0:  MAC = '{eth0[0]}', IP4: '{eth0[1]}', IP6: '{eth0[2]}'")

wifi = ai.get_adapter_infos("wlan0")
if VERBOSE_LOG:
    print(f"wlan0: MAC = '{wifi[0]}', IP4: '{wifi[1]}', IP6: '{wifi[2]}'")

HOSTNAME = ""
try:
    HOSTNAME = subprocess.check_output(f"hostname", shell=True, universal_newlines=True, timeout=2)
    if len(HOSTNAME.split("\n")) > 1:
        HOSTNAME = HOSTNAME.split("\n")[0]
except:
    HOSTNAME = ""

print(f"start service at port {HOST_PORT} @ {HOSTNAME}")
seed()   # int(dt.datetime.now().timestamp()))

def webhdr():
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
    if not v[0] and pwd == CONFIG_PWD:
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


#stylehdr = b'<head><meta http-equiv="refresh" content="0"/><style>p, button {font-size: 1em}</style><style>table, th, td {border: 1px solid black;}</style></head>'
stylehdr = b'<head><style>p, button {font-size: 1em}</style><style>table, th, td {border: 1px solid black;}</style>'

def HEADstr(t : str):
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

    def scanner_status(self):
        scanner_status_err = True
        try:
            out_status = subprocess.check_output(BIN_DIR+"statusBgScanLoop.sh", shell=True, universal_newlines=True, timeout=3)
            scanner_status_err = False
        except:
            scanner_status_err = True
            out_status = "ERROR at statusBgScanLoop.sh"
        if not scanner_status_err:
            out_status = out_status.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\n","<br>")
        self.wfile.write(str.encode( f"<p>{out_status}</p>"))


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
        self.wfile.write( webhdr().encode() )
        if VERBOSE_LOG:
            self.wfile.write(str.encode( f"<p>requested URL path: '{self.path}'</p>"))
            self.wfile.write(str.encode( f"<p>Your session '{session}: successful login {loggedIn}: {sv}'</p>"))
            self.wfile.write(str.encode( f"<p>Your IP:port {self.client_address[0]}:{self.client_address[1]}</p>"))
            print(f"\nrequested URL: {self.path}")
            print(f"requested URL path part: {ps}")
            print(f"requested URL get part:  {gps}")

        if not loggedIn:
            if ps=="/status":
                self.scanner_status()
                self.wfile.write(str.encode( f'<br><p><a href="/status?session={session}">Reload/Update Scanner Status</a> every 3 seconds ..</p>'))
            else:
                self.wfile.write(f'<h1>Login required</h1>'.encode())
                self.wfile.write(f'<form action="?session={session}" method="POST" enctype="application/x-www-form-urlencoded">'.encode())
                self.wfile.write(b'<span>Config password:</span>')
                self.wfile.write(b'<input type="password" id="pwd" name="pwd">')
                self.wfile.write(f'<input type="hidden" id="session" name="session" value="{session}">'.encode())
                self.wfile.write(b'<button style="color:blue">Submit</button>')
                self.wfile.write(b'</form>')
                self.wfile.write(str.encode( f'<br><p>without login only <a href="/status?session={session}">Show Scanner Status</a> available</p>'))

        else:
            if ps=="/wifi":
                self.wfile.write(f'<h1>WiFi configuration</h1>'.encode())
                self.wfile.write(f'<form action="/wifi?session={session}" method="POST" enctype="application/x-www-form-urlencoded">'.encode())
                self.wfile.write(b'<span>Wifi SSID:</span>')
                self.wfile.write(f'<input type="text" id="ssid" name="ssid">'.encode())
                self.wfile.write(b'<br><span>WPA/2 passphrase:</span>')
                self.wfile.write(b'<input type="password" id="pwd" name="pwd">')
                self.wfile.write(b'<button style="color:blue">Submit</button>')
                self.wfile.write(b'</form>')

            elif ps=="/wifi_reset":
                self.wfile.write(f'<h1>RESET ALL WiFi CONFIG</h1>'.encode())
                self.wfile.write(f'<form action="/wifi_reset?session={session}" method="POST" enctype="application/x-www-form-urlencoded">'.encode())
                self.wfile.write(f'<input type="hidden" id="wifi_reset" name="wifi_reset">'.encode())
                self.wfile.write(b'<button style="color:blue">RESET CONFIG</button>')
                self.wfile.write(b'</form>')

            elif ps=="/status":
                self.scanner_status()

            elif ps=="/reboot":
                self.wfile.write(f'<h1>Reboot Machine?</h1>'.encode())
                self.wfile.write(f'<form action="/reboot?session={session}" method="POST" enctype="application/x-www-form-urlencoded">'.encode())
                self.wfile.write(f'<input type="hidden" id="reboot" name="reboot">'.encode())
                self.wfile.write(b'<button style="color:blue">REBOOT</button>')
                self.wfile.write(b'</form>')

            elif ps=="/shutdown":
                self.wfile.write(f'<h1>Shutdown Machine?</h1>'.encode())
                self.wfile.write(f'<form action="/shutdown?session={session}" method="POST" enctype="application/x-www-form-urlencoded">'.encode())
                self.wfile.write(f'<input type="hidden" id="shutdown" name="shutdown">'.encode())
                self.wfile.write(b'<button style="color:blue">SHUTDOWN</button>')
                self.wfile.write(b'</form>')

            elif ps=="/config_pwd":
                self.wfile.write(f'<h1>Change Config Passphrase</h1>'.encode())
                self.wfile.write(f'<form action="/config_pwd?session={session}" method="POST" enctype="application/x-www-form-urlencoded">'.encode())
                self.wfile.write(b'<span>Old passphrase:</span>')
                self.wfile.write(f'<input type="password" id="old_pwd" name="old_pwd">'.encode())
                self.wfile.write(b'<br><span>New passphrase:</span>')
                self.wfile.write(b'<input type="password" id="new_pwd" name="new_pwd">')
                self.wfile.write(b'<button style="color:blue">Submit</button>')
                self.wfile.write(b'</form>')

            else:
                self.wfile.write(f'<h1>Menu</h1>'.encode())
                self.wfile.write(str.encode( f'<p><a href="/status?session={session}">Show Scanner Status</a></p>'))
                self.wfile.write(str.encode( f'<p><a href="/wifi?session={session}">Add WiFi Config</a></p>'))
                self.wfile.write(str.encode( f'<p><a href="/wifi_reset?session={session}">Reset All WiFi Config</a></p>'))
                self.wfile.write(str.encode( f'<p><a href="/reboot?session={session}">Reboot Machine</a></p>'))
                self.wfile.write(str.encode( f'<p><a href="/shutdown?session={session}">Shutdown Machine</a></p>'))
                self.wfile.write(str.encode( f'<p><a href="/config_pwd?session={session}">Change Config Passphrase</a></p>'))

        self.wfile.write(str.encode( f'<br><p>back to <a href="/?session={session}">menu</a></p>'))
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
        reloadURL = joinURL(ps, f"session={session}")

        if ps=="/wifi":
            wifi_conf_prep_err = True
            wifi_conf_fin_err = True
            wifi_reload_err = True

            try:
                out_prep = subprocess.check_output(BIN_DIR+"scannerPrepareWifiConfig.sh", shell=True, universal_newlines=True, timeout=3)
                wifi_conf_prep_err = False
            except:
                wifi_conf_prep_err = True
                out_prep = "ERROR at scannerPrepareWifiConfig.sh"

            if not wifi_conf_prep_err:
                with open("/dev/shm/wpa_supplicant/wpa_supplicant.conf", "a") as wpafile:
                    wpafile.write('\n\nnetwork={\n')
                    wpafile.write('  ssid="{}"\n'.format(d["ssid"]))
                    wpafile.write('  psk="{}"\n'.format(d["pwd"]))
                    wpafile.write('}\n\n')
                    wpafile.close()
                try:
                    out_fin = subprocess.check_output(BIN_DIR+"scannerFinalizeWifiConfig.sh", shell=True, universal_newlines=True, timeout=3)
                    wifi_conf_fin_err = False
                except:
                    wifi_conf_fin_err = True
                    out_fin = "ERROR at scannerFinalizeWifiConfig.sh"
                if not wifi_conf_fin_err:
                    try:
                        # "wpa_cli" requires "sudo apt install wpasupplicant"
                        out_reload = subprocess.check_output("wpa_cli -i wlan0 reconfigure", shell=True, universal_newlines=True, timeout=10)
                        wifi_reload_err = False
                    except:
                        wifi_reload_err = True
                        out_reload = "ERROR at 'wpa_cli -i wlan0 reconfigure'"

        elif ps=="/wifi_reset":
            wifi_reset_err = True
            wifi_reload_err = True

            try:
                out_prep = subprocess.check_output(BIN_DIR+"scannerResetWifiConfig.sh", shell=True, universal_newlines=True, timeout=3)
                wifi_reset_err = False
            except:
                wifi_reset_err = True
                out_prep = "ERROR at scannerResetWifiConfig.sh"

            if not wifi_reset_err:
                try:
                    # "wpa_cli" requires "sudo apt install wpasupplicant"
                    out_reload = subprocess.check_output("wpa_cli -i wlan0 reconfigure", shell=True, universal_newlines=True, timeout=10)
                    wifi_reload_err = False
                except:
                    wifi_reload_err = True
                    out_reload = "ERROR at 'wpa_cli -i wlan0 reconfigure'"

        elif ps=="/reboot":
            try:
                tmp = subprocess.check_output(BIN_DIR+"stopBgScanLoop.sh", shell=True, universal_newlines=True, timeout=1)
            except:
                pass

            try:
                out = subprocess.check_output(f'sudo shutdown -r +1 "reboot from local web control"', shell=True, universal_newlines=True, timeout=1)
                out = out.replace("\n","<br>")
            except:
                out = "ERROR at sudo shutdown -r .."

        elif ps=="/shutdown":
            try:
                tmp = subprocess.check_output(BIN_DIR+"stopBgScanLoop.sh", shell=True, universal_newlines=True, timeout=1)
            except:
                pass

            try:
                out = subprocess.check_output(f'sudo shutdown -p +1 "poweroff from local web control"', shell=True, universal_newlines=True, timeout=1)
                out = out.replace("\n","<br>")
            except:
                out = "ERROR at sudo shutdown -p .."

        elif ps=="/config_pwd":
            config_pwd_status = ""
            if not CONFIG_PWD == d["old_pwd"]:
                config_pwd_status = "Error: old passphrase does not match!"
            elif len(d["new_pwd"].rstrip()) < 4:
                config_pwd_status = "Error: new passphrase too short. minimum 4 characters required!"
            else:
                try:
                    with open(PWD_FILE, "w") as pwdf:
                        pwdf.write(d["new_pwd"].rstrip())
                        pwdf.close()
                    config_pwd_status = "Saved new passphrase."
                except:
                    config_pwd_status = "Error saving new passphrase!"
        else:
            pass

        self.send_response(200)
        #self.wfile.write(stylehdr)
        self.wfile.write( HEADstr( f'<meta http-equiv="refresh" content="5; url={reloadURL}">') )
        self.wfile.write(b'<body>')
        self.wfile.write( webhdr().encode() )

        if VERBOSE_LOG:
            self.wfile.write(str.encode( f"<p>requested POST URL path: '{self.path}'</p>"))
            self.wfile.write(str.encode( f"<p>Your session '{session}: successful login {loggedIn}: {sv}'</p>"))
            self.wfile.write(str.encode( f"<p>Your IP:port {self.client_address[0]}:{self.client_address[1]}</p>"))
            print(f"\nrequested URL: {self.path}")
            print(f"requested URL path part: {ps}")
            print(f"requested URL get part:  {gps}")

        self.wfile.write(f'<h1>Function </h1>'.encode())

        if ps=="/wifi":
            self.wfile.write(str.encode( f"<p>application / wait for wifi ..</p>"))
        elif ps=="/wifi_reset":
            self.wfile.write(str.encode( f"<p>application / wait for wifi ..</p>"))
        elif ps=="/reboot":
            self.wfile.write(str.encode( f"<p>REBOOT in 1 minute.</p>"))
            self.wfile.write(str.encode( f"<p>REBOOT output: out = {out}</p>"))
        elif ps=="/shutdown":
            self.wfile.write(str.encode( f"<p>POWER OFF in 1 minute.</p>"))
            self.wfile.write(str.encode( f"<p>POWER OFF output: out = {out}</p>"))
        elif ps=="/config_pwd":
            self.wfile.write(str.encode( f"<p>{config_pwd_status}</p>"))
        else:
            #self.wfile.write(str.encode( f"<p>Unknown URL path '{ps}'!</p>"))
            pass

        self.wfile.write(str.encode( f'<p>will reload site with GET, to get rid of POST parameters, in few seconds ..</p>'))
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


