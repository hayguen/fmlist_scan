#!/usr/bin/env python3

from http.server import HTTPServer, BaseHTTPRequestHandler
import ssl
import datetime as dt
from random import seed, random
import urllib
import subprocess
import os

import get_adapter_infos as ai

use_SSL = False   # False / True
SSL_key="/dev/shm/cert/rpi_scanner.key"
SSL_cert="/dev/shm/cert/rpi_scanner.crt"

# defaults for HOST_PORT: http: 80, https: 443, http proxy: 8080, https proxy: 4443
HOST_PORT = 8000
HOST_ADDRESS = ""
CONFIG_PWD = "hello"   # todo: read from a file
LOGIN_EXPIRATION_SECS = 60

#### session is key
# value is tuple of (logged :bool, last_IP :str, timeout :)
SESSIONS = dict()


eth0 = ai.get_adapter_infos("eth0")
print(f"eth0:  MAC = '{eth0[0]}', IP4: '{eth0[1]}', IP6: '{eth0[2]}'")

wifi = ai.get_adapter_infos("wlan0")
print(f"wlan0: MAC = '{wifi[0]}', IP4: '{wifi[1]}', IP6: '{wifi[2]}'")

HOSTNAME = ""
try:
    HOSTNAME = subprocess.check_output(f"hostname", shell=True, universal_newlines=True, timeout=2)
    if len(HOSTNAME.split("\n")) > 1:
        HOSTNAME = HOSTNAME.split("\n")[0]
except:
    HOSTNAME = ""

print(f"start service at port {HOST_PORT} @ {HOSTNAME}")
seed(1)

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
        print(f"removing expired session {s}: {v}")
        del SESSIONS[s]

    if session is None or len(session) <= 0:
        session = new_session(curr_IP)
        print(f"created new session '{session}' : was empty")

    if session in SESSIONS:
        v = SESSIONS[session]
        if v[1] != curr_IP:
            session = new_session(curr_IP)
            print(f"created new session '{session}' : IP mismatch")
        elif v[2] < present:
            SESSIONS[session] = (False, curr_IP, new_exp )
            print(f"session '{session}' expired: logged off")
    else:
        SESSIONS[session] = (False, curr_IP, new_exp)
        print(f"created non existing session '{session}'")

    # always update expiration
    v = SESSIONS[session]
    if not v[0] and pwd == CONFIG_PWD:
        v = ( True, curr_IP, new_exp )
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

    def do_GET(self):
        """ response for a GET request """
        if self.path == "/favicon.ico":
            self.send_response(404)
            return
        (d, session_changed) = self.get_fields(False)
        print(d)
        print(f"GET fields session changed {session_changed}")
        session=d["session"]
        sv = SESSIONS[session]
        loggedIn = sv[0]
        (ps, gps) = splitURL(self.path)
        reloadURL = joinURL(ps, f"session={session}")

        self.send_response(200)
        if session_changed:
            print(f"reload {reloadURL} in 1 sec .. (ps='{ps}', session={session}")
            self.wfile.write( HEADstr( f'<meta http-equiv="refresh" content="1; url={reloadURL}">') )
        else:
            self.wfile.write( HEADstr("") )

        self.wfile.write(b'<body>')
        self.wfile.write( webhdr().encode() )
        self.wfile.write(str.encode( f"<p>requested URL path: '{self.path}'</p>"))
        self.wfile.write(str.encode( f"<p>Your session '{session}: successful login {loggedIn}: {sv}'</p>"))
        self.wfile.write(str.encode( f"<p>Your IP:port {self.client_address[0]}:{self.client_address[1]}</p>"))
        print(f"\nrequested URL: {self.path}")
        print(f"requested URL path part: {ps}")
        print(f"requested URL get part:  {gps}")

        if not loggedIn:
            self.wfile.write(f'<h1>Login required</h1>'.encode())
            self.wfile.write(f'<form action="?session={session}" method="POST" enctype="application/x-www-form-urlencoded">'.encode())
            self.wfile.write(b'<span>Config password:</span>')
            self.wfile.write(b'<input type="password" id="pwd" name="pwd">')
            self.wfile.write(f'<input type="hidden" id="session" name="session" value="{session}">'.encode())
            self.wfile.write(b'<button style="color:blue">Submit</button>')
            self.wfile.write(b'</form>')
        else:
            if ps=="/wifi":
                self.wfile.write(f'<h1>WiFi configuration</h1>'.encode())
                self.wfile.write(str.encode( f'<p>TODO: show form POSTing SSID and password fields</p>'))
            elif ps=="/reboot":
                self.wfile.write(f'<h1>Reboot Machine</h1>'.encode())
                self.wfile.write(str.encode( f'<p>TODO: show pseudo form POSTing just a hidden dummy field</p>'))
            elif ps=="/shutdown":
                self.wfile.write(f'<h1>Shutdown Machine</h1>'.encode())
                self.wfile.write(str.encode( f'<p>TODO: show pseudo form POSTing just a hidden dummy field</p>'))
            else:
                self.wfile.write(f'<h1>Menu</h1>'.encode())
                self.wfile.write(str.encode( f'<p><a href="/wifi?session={session}">WiFi</a></p>'))
                self.wfile.write(str.encode( f'<p><a href="/reboot?session={session}">Reboot Machine</a></p>'))
                self.wfile.write(str.encode( f'<p><a href="/shutdown?session={session}">Shutdown Machine</a></p>'))

        self.wfile.write(str.encode( f'<br><p>back to <a href="/?session={session}">menu</a></p>'))
        self.wfile.write(b'</body>')

    def do_POST(self):
        """ response for a POST """
        (d, session_changed) = self.get_fields(True)
        print(d)
        print(f"GET fields session changed {session_changed}")
        session=d["session"]
        sv = SESSIONS[session]
        loggedIn = sv[0]
        (ps, gps) = splitURL(self.path)
        reloadURL = joinURL(ps, f"session={session}")

        self.send_response(200)
        #self.wfile.write(stylehdr)
        self.wfile.write( HEADstr( f'<meta http-equiv="refresh" content="5; url={reloadURL}">') )
        self.wfile.write(b'<body>')
        self.wfile.write( webhdr().encode() )

        self.wfile.write(str.encode( f"<p>requested POST URL path: '{self.path}'</p>"))
        self.wfile.write(str.encode( f"<p>Your session '{session}: successful login {loggedIn}: {sv}'</p>"))
        self.wfile.write(str.encode( f"<p>Your IP:port {self.client_address[0]}:{self.client_address[1]}</p>"))
        print(f"\nrequested URL: {self.path}")
        print(f"requested URL path part: {ps}")
        print(f"requested URL get part:  {gps}")

        self.wfile.write(f'<h1>Function </h1>'.encode())
        self.wfile.write(str.encode( f"<p>TODO here: execute some command depending on URL path '{ps}' and print result</p>"))
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


