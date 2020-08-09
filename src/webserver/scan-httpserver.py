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
import shlex
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
config_fn_rel_to_home = "/.config/fmlist_scan/config"

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


def read_all_lines(fn):
    try:
        with open(fn, "r") as f:
            cc = f.readlines()
            f.close()
    except:
        print(f"error reading file {fn}")
        return None
    return cc

def write_all_lines(fn_new, cc):
    try:
        with open(fn_new, "w") as f:
            f.writelines(cc)
            f.close()
            return True
    except:
        print("error writing config")
        return False

def find_export_line(cc, varname):
    sstr = f'export {varname}="'
    slen = len(sstr)
    for lno in range(len(cc)):
        if cc[lno][:slen] == sstr:
            return lno
    return None

def get_export_value_pos(ln, varname):
    sstr = f'export {varname}="'
    slen = len(sstr)
    #print(ln[slen-1])
    epos = ln.find('"', slen)
    if epos >= 0:
        return (slen, epos)
    else:
        return None

def get_export_value(cc, varname):
    lno = find_export_line(cc, varname)
    if lno is None:
        return None
    ln = cc[lno]
    pp = get_export_value_pos(ln, varname)
    if pp is None:
        return None
    value = ln[pp[0]:pp[1]]
    return value

def replace_export_value(cc, varname, new_value):
    lno = find_export_line(cc, varname)
    if lno is None:
        return False
    ln = cc[lno]
    pp = get_export_value_pos(ln, varname)
    if pp is None:
        return False
    ln_new = ln[0:pp[0]] + new_value + ln[pp[1]:]
    cc[lno] = ln_new
    return True

def remove_fmlist_prefix(varname):
    dk = varname
    if dk[:7] == "FMLIST_":
        dk = dk[7:]
    return dk

def dict_keyname_from_conf_varname(varname):
    return remove_fmlist_prefix(varname).lower()

def read_and_gen_text_form_from_cfg(varnames_w_comment, cfg_dict, cc_config):
    form_cont = ""
    for vc in varnames_w_comment:
        v = vc[0]
        v_name = remove_fmlist_prefix(v)
        dict_key = v_name.lower()
        cfg_dict[dict_key] = get_export_value(cc_config, v)
        if cfg_dict[dict_key] is None:
            print(f"Error reading {v} from config")
            cfg_dict[dict_key] = ""
        #print(f"{v} / {dict_key}: {cfg_dict[dict_key]}")
        form_cont = form_cont + f'<tr><td>{v_name}</td><td><input type="text" id="cfg_{dict_key}" name="cfg_{dict_key}" value="{cfg_dict[dict_key]}"> </td><td>{vc[1]}</td></tr>'
    return form_cont

def read_and_gen_textarea_form_from_cfg(varnames_w_comment, cfg_dict, cc_config, rowcount, colcount):
    form_cont = ""
    for vc in varnames_w_comment:
        v = vc[0]
        v_name = remove_fmlist_prefix(v)
        dict_key = v_name.lower()
        cfg_dict[dict_key] = get_export_value(cc_config, v)
        if cfg_dict[dict_key] is None:
            print(f"Error reading {v} from config")
            cfg_dict[dict_key] = ""
        #print(f"{v} / {dict_key}: {cfg_dict[dict_key]}")
        cont = cfg_dict[dict_key].replace('\r','').replace('<br>', '\n')
        form_cont = form_cont + f'<tr><td>{v_name}</td><td><textarea name="cfg_{dict_key}" rows="{rowcount}" cols="{colcount}">{cfg_dict[dict_key]}</textarea> </td><td>{vc[1]}</td></tr>'
    return form_cont

def read_and_gen_combo_form_from_cfg(varnames_w_comment, cfg_dict, cc_config, options):
    form_cont = ""
    for vc in varnames_w_comment:
        v = vc[0]
        v_name = remove_fmlist_prefix(v)
        dict_key = v_name.lower()
        cfg_dict[dict_key] = get_export_value(cc_config, v)
        if cfg_dict[dict_key] is None:
            print(f"Error reading {v} from config")
            cfg_dict[dict_key] = ""
        #print(f"{v} / {dict_key}: {cfg_dict[dict_key]}")
        form_cont = form_cont + f'<tr><td>{v_name}</td><td><select id="cfg_{dict_key}" name="cfg_{dict_key}">'
        for opt in options:
            selopt = ""
            if opt[0] == cfg_dict[dict_key]:
                selopt = 'selected="true"'
            form_cont = form_cont + f'<option {selopt} value="{opt[0]}">{opt[1]}</option>'
        form_cont = form_cont + f'</select></td><td>{vc[1]}</td></tr>'
    return form_cont

def read_and_gen_check_form_from_cfg(varnames_w_comment, cfg_dict, cc_config):
    form_cont = ""
    for vc in varnames_w_comment:
        v = vc[0]
        v_name = remove_fmlist_prefix(v)
        dict_key = v_name.lower()
        cfg_dict[dict_key] = get_export_value(cc_config, v)
        if cfg_dict[dict_key] is None:
            print(f"Error reading {v} from config")
            cfg_dict[dict_key] = ""
        #print(f"{v} / {dict_key}: {cfg_dict[dict_key]}")
        checked_txt = ""
        if cfg_dict[dict_key] == "1":
            checked_txt = "checked"
        form_cont = form_cont + f'<tr><td>{v_name}</td><td><input type="checkbox" id="cfg_{dict_key}" name="cfg_{dict_key}" value="1" {checked_txt}> </td><td>{vc[1]}</td></tr>'
    return form_cont


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


def run_and_get_output(prependBinDir, cmd, timeout_val_in_sec, replace_html_chars = True):
    cmdhtml = cmd.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\n","<br>")
    if prependBinDir:
        cmd_exec = BIN_DIR+cmd
    else:
        cmd_exec = cmd
    err_at_exec = False
    try:
        out = subprocess.check_output(cmd_exec, shell=True, universal_newlines=True, timeout=timeout_val_in_sec)
        if replace_html_chars:
            outhtml = out.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\n","<br>")
        else:
            outhtml = out
        ret = f"<p>Output of {cmdhtml}:</p><p>{outhtml}</p>"
    except subprocess.TimeoutExpired:
        err_at_exec = True
        ret = f"<p>Timeout executing {cmdhtml}!</p>"
    except:
        err_at_exec = True
        ret = f"<p>Error executing {cmdhtml}!</p>"
    return (ret, err_at_exec)


def run_in_background(prependBinDir, cmd, timeout_val_in_sec, replace_html_chars = True):
    cmdhtml = cmd.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\n","<br>")
    if prependBinDir:
        cmd_exec = BIN_DIR+cmd
    else:
        cmd_exec = cmd
    err_at_exec = False
    try:
        cl = shlex.split(cmd_exec)
        pid = subprocess.Popen(cl)
        outhtml = ""
        ret = f"<p>Output of {cmdhtml}:</p><p>{outhtml}</p>"
    except subprocess.TimeoutExpired:
        print("Exception TimeoutExpired")
        err_at_exec = True
        ret = f"<p>Timeout executing {cmdhtml}!</p>"
    except:
        print("Exception")
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
    if p.endswith(".html"):
        p = p[ : -5]
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
        x = stylehdr + str.encode(t) + b'</head>\n'
    else:
        x = stylehdr + b'</head>\n'
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
        s = f'<form action="/{f}.html?session={session}" method="POST" enctype="application/x-www-form-urlencoded">'
        s = s + f'<input type="hidden" id="action" name="action" value="{f}">'
        s = s + f'<button style="color:blue">{t}</button>'
        s = s + '</form>'
        return s

    def create_html_form(self, f, t, session ):
        self.wfile.write(str.encode( self.create_html_form_str(f, t, session) ))


    def GET_menu(self, session):
        self.wfile.write(f'<h1>FMLIST-Scanner Menu</h1>'.encode())
        r = '<table>\n'
        r = r + f'<tr><td><p><a href="/status.html?session={session}">Show Scanner Status</a></p><br>' + '</td>\n'
        r = r + f'<td><p><a href="/versions.html?session={session}">Version info</a></p><br>' + '</td></tr>\n'
        r = r + '<tr><td>' + f'<p><a href="/wifi.html?session={session}">Add WiFi Config</a></p><br>' + '</td>\n'
        r = r + '<td>' + f'<p><a href="/wifi_reset.html?session={session}">Reset All WiFi Config</a></p><br>' + '</td></tr>\n'
        r = r + '<tr><td colspan="2">' + self.create_html_form_str("wifi_reconfig", "Reconfigure WiFi", session ) + '</td></tr>\n'
        r = r + '<tr><td colspan="2">' + f'<p><a href="/config.html?session={session}">Configure Scanner</a></p><br>' + '</td></tr>\n'
        r = r + '<tr><td>' + self.create_html_form_str("start_scanner", "Start Scanner", session ) + '</td>\n'
        r = r + '<td>' + self.create_html_form_str("stop_scanner", "Stop Scanner", session ) + '</td></tr>\n'
        r = r + '<tr><td>' + self.create_html_form_str("prepare_upload_all", "Prepare All &amp; Upload", session ) + '</td>\n'
        r = r + '<td>' + self.create_html_form_str("upload_results", "Upload Results", session ) + '</td></tr>\n'
        r = r + '<tr><td colspan="2">' + f'<p><a href="/test_tones.html?session={session}">Test / Listen Buzzer Messages<br>for recognition training</a></p><br>' + '</td></tr>\n'
        r = r + '<tr><td>' + f'<p><a href="/reboot.html?session={session}">Reboot Machine</a></p><br>' + '</td>\n'
        r = r + '<td>' + f'<p><a href="/shutdown.html?session={session}">Shutdown Machine</a></p><br>' + '</td></tr>\n'
        r = r + '<tr><td colspan="2">' + f'<p><a href="/config_pwd.html?session={session}">Change Config Passphrase</a></p><br>' + '</td></tr>\n'
        r = r + '<tr><td colspan="2">' + self.create_html_form_str("logout", "Logout", session ) + f'expiration is at {SESSIONS[session][2]}<br>current date/time: {dt.datetime.now()}' + '</td></tr>\n'
        r = r + '</table>'
        self.wfile.write(str.encode(r))


    def GET_test_tones(self, session, d):
        self.wfile.write(f'<h1>FMLIST-Scanner Menu</h1>'.encode())
        self.wfile.write(f'<h2>Test / Listen Buzzer-Messages</h2>'.encode())
        r = '<table>\n'
        r = r + f'<tr><td colspan="2"><a href="/test_tones.html?session={session}&message=welcome">Welcome at Start</a></td></tr>\n'
        r = r + f'<tr><td><a href="/test_tones.html?session={session}&message=fm_good">UKW/FM found station(s): OK</a>' + '</td>\n'
        r = r + f'    <td><a href="/test_tones.html?session={session}&message=fm_fail">UKW/FM found NO station(s): FAIL</a></td></tr>\n'
        r = r + f'<tr><td><a href="/test_tones.html?session={session}&message=dab_good">DAB found station(s): OK</a></td>\n'
        r = r + f'    <td><a href="/test_tones.html?session={session}&message=dab_fail">DAB found NO station(s): FAIL</a></td></tr>\n'
        r = r + f'<tr><td><a href="/test_tones.html?session={session}&message=saved">Saved Results of Scan</a></td>\n'
        r = r + f'    <td><a href="/test_tones.html?session={session}&message=final">Finished/Stopped Scan</a></td></tr>\n'
        r = r + f'<tr><td colspan="2"><a href="/test_tones.html?session={session}&message=write_err">ERROR writing Scan-Results!</a></td></tr>\n'
        r = r + f'<tr><td colspan="2"><a href="/test_tones.html?session={session}&message=error">Some ERROR.</a></td></tr>\n'
        r = r + '</table>'
        self.wfile.write(str.encode(r))
        if "message" in d:
            m = d["message"]
            if m in [ "welcome", "saved", "final", "write_err", "error" ]:
                out_html, err_at_exec = run_in_background(True, f"scanToneFeedback.sh {m}", 1)
                if not err_at_exec:
                    self.wfile.write(str.encode( f'<br><p>in case of correct configuration of pins .. you should hear message for &quot;{m}&quot; once</p>'))
                else:
                    self.wfile.write(str.encode( f'<br><p>Error executing scanToneFeedback.sh!</p>'))
            elif m in [ "fm_good", "fm_fail", "dab_good", "dab_fail" ]:
                if m == "fm_good":
                    tone_param = "fm 1"
                elif m == "fm_fail":
                    tone_param = "fm 0"
                elif m == "dab_good":
                    tone_param = "dab 1"
                elif m == "dab_fail":
                    tone_param = "dab 0"
                out_html, err_at_exec = run_in_background(True, f"scanToneFeedback.sh {tone_param}", 1)
                if not err_at_exec:
                    self.wfile.write(str.encode( f'<br><p>in case of correct configuration of pins .. you should hear message for &quot;{m}&quot; once</p>'))
                else:
                    self.wfile.write(str.encode( f'<br><p>Error executing scanToneFeedback.sh!</p>'))
            else:
                self.wfile.write(str.encode( f'<br><p>unknown message &quot;{m}&quot; !</p>'))


    def GET_config(self, session):
        self.wfile.write(f'<h1>FMLIST-Scanner Menu</h1>'.encode())
        self.wfile.write(f'<h2>Configure Scanner</h2>'.encode())

        while True:
            home = os.getenv("HOME")
            cc_config = read_all_lines(home + config_fn_rel_to_home)
            if cc_config is None:
                out_html = '<p>Error reading "config" file!</p>'
                break

            gps_qth_prefix = get_export_value(cc_config, "FMLIST_QTH_PREFIX")
            gps_lat = get_export_value(cc_config, "FMLIST_SCAN_GPS_LAT")
            gps_lon = get_export_value(cc_config, "FMLIST_SCAN_GPS_LON")
            gps_alt = get_export_value(cc_config, "FMLIST_SCAN_GPS_ALT")
            
            while gps_qth_prefix is not None and len(gps_qth_prefix) > 0:
                cc_gps = read_all_lines(home+"/.config/fmlist_scan/"+gps_qth_prefix+"_GPS_COORDS.inc")
                if cc_gps is None:
                    print("Error reading local GPS config")
                    break
                gps_loc_lat = get_export_value(cc_gps, "FMLIST_SCAN_GPS_LAT")
                gps_loc_lon = get_export_value(cc_gps, "FMLIST_SCAN_GPS_LON")
                gps_loc_alt = get_export_value(cc_gps, "FMLIST_SCAN_GPS_ALT")
                if gps_loc_lat is not None and len(gps_loc_lat) > 0:
                    gps_lat = gps_loc_lat
                if gps_loc_lon is not None and len(gps_loc_lon) > 0:
                    gps_lon = gps_loc_lon
                if gps_loc_alt is not None and len(gps_loc_alt) > 0:
                    gps_alt = gps_loc_alt
                break

            cfg_dict = dict()
            form_cont = ""

            # ********************
            form_cont = form_cont + '<tr><td colspan="3"><br><b>&nbsp;General / System data</b></td></tr>'
            form_cont = form_cont + '<tr><th>Name</th><th>Value / Content</th><th>Description</th><tr>\n'

            form_cont = form_cont + read_and_gen_text_form_from_cfg( [
              ("FMLIST_USER",     "contributor/RaspiEmail shown in URDS table, used for login at https://www.fmlist.org/"),
              ("FMLIST_RASPI_ID", "RaspiId shown in URDS table at https://www.fmlist.org/<br>use to identify THIS device") ],
              cfg_dict, cc_config )

            form_cont = form_cont + f'<tr><td>QTH_PREFIX</td><td><input type="text" id="cfg_qth_prefix" name="cfg_qth_prefix" value="{str(gps_qth_prefix)}"> </td><td>prefix for config filename for _GPS_COORDS.inc<br>usually "local"</td></tr>'
            form_cont = form_cont + f'<tr><td>SCAN_GPS_LAT</td><td><input type="text" id="cfg_gps_lat" name="cfg_gps_lat" value="{str(gps_lat)}"> </td><td>decimal latitude, e.g. 48.885582 </td></tr>'
            form_cont = form_cont + f'<tr><td>SCAN_GPS_LON</td><td><input type="text" id="cfg_gps_lon" name="cfg_gps_lon" value="{str(gps_lon)}"> </td><td>decimal longitude, e.g. 8.702656 </td></tr>'
            form_cont = form_cont + f'<tr><td>SCAN_GPS_ALT</td><td><input type="text" id="cfg_gps_alt" name="cfg_gps_alt" value="{str(gps_alt)}"> </td><td>decimal altitude, e.g. 307 </td></tr>'

            form_cont = form_cont + read_and_gen_check_form_from_cfg( [
              ("FMLIST_SCAN_AUTOSTART",    "autostart scanner in background, when booting"),
              ("FMLIST_SCAN_AUTO_IP_INFO", "notify fmlist.org of local IP address(es), to get a link to local webserver at MyURDS"),
              ("FMLIST_SCAN_AUTO_CONFIG",  "permit configuration from fmlist.org in MyURDS"),
              ("FMLIST_SCAN_FM",           "scan UKW/FM stations - requires restart of scanner"),
              ("FMLIST_SCAN_DAB",          "scan DAB stations - requires restart of scanner"),
              ("FMLIST_ALWAYS_FAST_MODE",  "deactivates verbose scan when GPS not connected"),
              ("FMLIST_SPORADIC_E_MODE",   "deactivates DAB scan, uses special scan parameters in FM for quick scan") ],
              cfg_dict, cc_config )

            # ********************
            form_cont = form_cont + '<tr><td colspan="3"><br><b>&nbsp;Data for next prepare / upload</b></td></tr>'
            form_cont = form_cont + '<tr><th>Name</th><th>Value / Content</th><th>Description</th><tr>\n'

            form_cont = form_cont + read_and_gen_text_form_from_cfg( [
              ("FMLIST_OM_ID",    "OMID shown in URDS table at https://www.fmlist.org/<br>use OMID fixed positions. leave empty for mobile use") ],
              cfg_dict, cc_config )

            form_cont = form_cont + read_and_gen_textarea_form_from_cfg( [
              ("FMLIST_UP_COMMENT", "Upload Comments shown in URDS table") ],
              cfg_dict, cc_config, 3, 40 )

            form_cont = form_cont + read_and_gen_combo_form_from_cfg( [
              ("FMLIST_UP_POSITION", "Position for next upload") ],
              cfg_dict, cc_config, [ ("fixed", "fixed position"), ("mobile", "mobile") ] )

            form_cont = form_cont + read_and_gen_combo_form_from_cfg( [
              ("FMLIST_UP_PERMISSION", "Access Permissions for next upload") ],
              cfg_dict, cc_config,
              [ ("public", "public"), ("owner", "only me"), ("restrict", "restricted to following Email addresses") ] )
            form_cont = form_cont + read_and_gen_textarea_form_from_cfg( [
              ("FMLIST_UP_RESTRICT_USERS", "Email addresses of persons, permitted to view upload<br>split by space or line feed") ],
              cfg_dict, cc_config, 3, 40 )

            s = f'<form action="/config?session={session}" method="POST" enctype="application/x-www-form-urlencoded">'
            s = s + f'<input type="hidden" id="action" name="action" value="config">'
            s = s + "<table>"
            #s = s + "<tr><th>Name</th><th>Value / Content</th><th>Description</th><tr>\n"
            s = s + form_cont
            s = s + "</table><br>"
            s = s + f'<button style="color:blue">CONFIGURE</button>'
            s = s + '</form>'
            out_html = s
            break
        self.wfile.write(out_html.encode())


    def POST_config(self, session, d):
        print("*******************")
        print(d)
        print("*******************")
        while True:
            home = os.getenv("HOME")
            cc_config = read_all_lines(home + config_fn_rel_to_home)
            if cc_config is None:
                out_html = '<p>Error reading "config" file!</p>'
                break

            gps_qth_prefix = get_export_value(cc_config, "FMLIST_QTH_PREFIX")
            gps_lat = get_export_value(cc_config, "FMLIST_SCAN_GPS_LAT")
            gps_lon = get_export_value(cc_config, "FMLIST_SCAN_GPS_LON")
            gps_alt = get_export_value(cc_config, "FMLIST_SCAN_GPS_ALT")
            
            while gps_qth_prefix is not None and len(gps_qth_prefix) > 0:
                cc_gps = read_all_lines(home+"/.config/fmlist_scan/"+gps_qth_prefix+"_GPS_COORDS.inc")
                if cc_gps is None:
                    print("Error reading local GPS config")
                    break
                gps_loc_lat = get_export_value(cc_gps, "FMLIST_SCAN_GPS_LAT")
                gps_loc_lon = get_export_value(cc_gps, "FMLIST_SCAN_GPS_LON")
                gps_loc_alt = get_export_value(cc_gps, "FMLIST_SCAN_GPS_ALT")
                if gps_loc_lat is not None and len(gps_loc_lat) > 0:
                    gps_lat = gps_loc_lat
                if gps_loc_lon is not None and len(gps_loc_lon) > 0:
                    gps_lon = gps_loc_lon
                if gps_loc_alt is not None and len(gps_loc_alt) > 0:
                    gps_alt = gps_loc_alt
                break


            out_html = '<p>Read config file</p>'

            v = d["cfg_user"].replace('"','').replace('&','').replace(',','').replace(';','').replace('<','').replace('>','')
            replace_export_value(cc_config, "FMLIST_USER", v )

            v = d["cfg_raspi_id"].replace('"','').replace('&','').replace(',','').replace(';','').replace('<','').replace('>','')
            replace_export_value(cc_config, "FMLIST_RASPI_ID", v )

            v = d["cfg_qth_prefix"].replace('"','').replace('&','').replace(',','').replace(';','').replace('<','').replace('>','')
            gps_prefix_changed = False
            if gps_qth_prefix == v:
                # prefix did not change => we can use/write the coordinates
                v = d["cfg_gps_lat"].replace('"','').replace('&','').replace(',','').replace(';','').replace('<','').replace('>','')
                replace_export_value(cc_gps, "FMLIST_SCAN_GPS_LAT", v)
                v = d["cfg_gps_lon"].replace('"','').replace('&','').replace(',','').replace(';','').replace('<','').replace('>','')
                replace_export_value(cc_gps, "FMLIST_SCAN_GPS_LON", v)
                v = d["cfg_gps_alt"].replace('"','').replace('&','').replace(',','').replace(';','').replace('<','').replace('>','')
                replace_export_value(cc_gps, "FMLIST_SCAN_GPS_ALT", v)
            else:
                # change only the prefix
                replace_export_value(cc_config, "FMLIST_QTH_PREFIX", v )
                gps_qth_prefix = v
                gps_prefix_changed = True

            replace_export_value(cc_config, "FMLIST_SCAN_AUTOSTART",    "1" if "cfg_scan_autostart" in d    else "0")
            replace_export_value(cc_config, "FMLIST_SCAN_AUTO_IP_INFO", "1" if "cfg_scan_auto_ip_info" in d else "0")
            replace_export_value(cc_config, "FMLIST_SCAN_AUTO_CONFIG",  "1" if "cfg_scan_auto_config" in d  else "0")
            replace_export_value(cc_config, "FMLIST_SCAN_FM",           "1" if "cfg_scan_fm" in d           else "0")
            replace_export_value(cc_config, "FMLIST_SCAN_DAB",          "1" if "cfg_scan_dab" in d          else "0")
            replace_export_value(cc_config, "FMLIST_ALWAYS_FAST_MODE",  "1" if "cfg_always_fast_mode" in d  else "0")
            replace_export_value(cc_config, "FMLIST_SPORADIC_E_MODE",   "1" if "cfg_sporadic_e_mode" in d   else "0")

            v = d["cfg_om_id"].replace('"','').replace('&','').replace(',','').replace(';','').replace('<','').replace('>','')
            replace_export_value(cc_config, "FMLIST_OM_ID", v )

            v = d["cfg_up_comment"].replace('"',"'").replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('\r\n','<br>').replace('\r','').replace('\n','<br>').replace('\\r\\n', '<br>').replace('\\r','').replace('\\n','<br>')
            replace_export_value(cc_config, "FMLIST_UP_COMMENT", v )

            v = d["cfg_up_position"].replace('"','').replace('&','').replace(',','').replace(';','').replace('<','').replace('>','')
            replace_export_value(cc_config, "FMLIST_UP_POSITION", v )

            v = d["cfg_up_permission"].replace('"','').replace('&','').replace(',','').replace(';','').replace('<','').replace('>','')
            replace_export_value(cc_config, "FMLIST_UP_PERMISSION", v )

            v = d["cfg_up_restrict_users"].replace('"',"'").replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('\r\n',' ').replace('\r','').replace('\n',' ').replace('\\r\\n', ' ').replace('\\r','').replace('\\n',' ')
            replace_export_value(cc_config, "FMLIST_UP_RESTRICT_USERS", v )

            out_html = out_html + '<p>Replaced values.</p>'

            localFname = home+"/.config/fmlist_scan/"+gps_qth_prefix+"_GPS_COORDS.inc"
            if gps_prefix_changed:
                localf = Path(localFname)
                if not localf.is_file():
                    r = write_all_lines(localFname, cc_gps)
                    if r:
                        out_html = out_html + '<p>Wrote back local GPS config file.</p>'
                    else:
                        out_html = out_html + '<p>Error writing back local GPS config file!</p>'
            else:
                r = write_all_lines(localFname, cc_gps)
                if r:
                    out_html = out_html + '<p>Wrote back local GPS config file.</p>'
                else:
                    out_html = out_html + '<p>Error writing back local GPS config file!</p>'

            r = write_all_lines(home + config_fn_rel_to_home, cc_config)
            if r:
                out_html = out_html + '<p>Wrote back config file.</p>'
                return (out_html, True)
            else:
                out_html = out_html + '<p>Error writing back config file!</p>'
                return (out_html, False)

            break


    def POST_wifi(self, d):
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
        return (out_html, err_at_exec)


    def POST_config_pwd(self, d):
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
        return (out_html, err_at_exec)


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
        reloadURL = joinURL(ps + ".html", f"session={session}")

        self.send_response(200)
        self.wfile.write(str.encode('<!DOCTYPE html>\n<html lang="en-US">\n'))

        if session_changed:
            if VERBOSE_LOG:
                print(f"reload {reloadURL} in 1 sec .. (ps='{ps}', session={session}")
            self.wfile.write( HEADstr( f'<meta http-equiv="refresh" content="1; url={reloadURL}">') )
        elif ps=="/status":
            self.wfile.write( HEADstr( f'<meta http-equiv="refresh" content="3; url={reloadURL}">') )
        else:
            self.wfile.write( HEADstr("") )

        self.wfile.write(b'<body>\n')
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
                self.wfile.write(str.encode(f'<p><a href="/status.html?session={session}">Reload/Update Scanner Status</a> every 3 seconds ..</p>'))
            else:
                self.wfile.write(f'<h1>Login required</h1>'.encode())
                self.wfile.write(f'<form action="?session={session}" method="POST" enctype="application/x-www-form-urlencoded">'.encode())
                self.wfile.write(b'<span>Config password:</span>')
                self.wfile.write(b'<input type="password" id="pwd" name="pwd">')
                self.wfile.write(f'<input type="hidden" id="action" name="action" value="login">'.encode())
                self.wfile.write(f'<input type="hidden" id="session" name="session" value="{session}">'.encode())
                self.wfile.write(b'<button style="color:blue">Sign-In</button>')
                self.wfile.write(b'</form>')
                self.wfile.write(str.encode( f'<br><p>without login, only <a href="/status.html?session={session}">Show Scanner Status</a> is available</p>'))

        else:
            if ps=="/versions":
                out_html, err_at_exec = run_and_get_output(True, "scanner_versions.sh html", 3, False)
                self.wfile.write(str.encode(out_html))

            elif ps=="/wifi":
                self.wfile.write(f'<h1>WiFi configuration</h1>'.encode())
                self.wfile.write(f'<form action="/wifi?session={session}" method="POST" enctype="application/x-www-form-urlencoded">'.encode())
                self.wfile.write(b'<span>Wifi SSID:</span>')
                self.wfile.write(f'<input type="hidden" id="action" name="action" value="wifi">'.encode())
                self.wfile.write(f'<input type="text" id="ssid" name="ssid">'.encode())
                self.wfile.write(b'<br><span>WPA/2 passphrase:</span>')
                self.wfile.write(b'<input type="password" id="pwd" name="pwd">')
                self.wfile.write(b'<button style="color:blue">Add WiFi</button>')
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
                self.wfile.write(str.encode(f'<br><p><a href="/status.html?session={session}">Reload/Update Scanner Status</a> every 3 seconds ..</p>'))

            elif ps=="/config":
                self.GET_config(session)

            elif ps=="/test_tones":
                self.GET_test_tones(session, d)

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
                self.wfile.write(b'<button style="color:blue">Change</button>')
                self.wfile.write(b'</form>')

            else:
                self.GET_menu(session)

        self.wfile.write(str.encode( f'<p>back to <a href="/index.html?session={session}">menu</a></p>'))
        self.wfile.write(str.encode( f'<p>to <a href="https://groups.io/g/fmlist-scanner" target="_groups_io">Mailing List and Group at groups.io</a></p>'))
        self.wfile.write(str.encode( f'<p>to <a href="https://www.fmlist.org/" target="_fmlist_org">FMLIST.org</a>. look for the URDS menu.</p>'))
        self.wfile.write(b'</body>')
        self.wfile.write(b'</html>')

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
            reloadURL = "/index.html"

        elif ps=="/wifi":
            out_html, err_at_exec = self.POST_wifi(d)

        elif ps=="/wifi_reset":
            out_html, err_at_exec = run_and_get_output(True, "scannerResetWifiConfig.sh", 3)

        elif ps=="/wifi_reconfig":
            # "wpa_cli" requires "sudo apt install wpasupplicant"
            out_html, err_at_exec = run_in_background(True, "scannerReconfigWifi.sh", 1)

        elif ps=="/config":
            out_html, err_at_exec = self.POST_config(session, d)

        elif ps=="/start_scanner":
            out_html, err_at_exec = run_in_background(True, "startBgScanLoop.sh", 1)

        elif ps=="/stop_scanner":
            out_html, err_at_exec = run_in_background(True, "stopBgScanLoop.sh", 1)

        elif ps=="/prepare_upload_all":
            out_html, err_at_exec = run_and_get_output(False, f"( {BIN_DIR}prepareScanResultsForUpload.sh all ; {BIN_DIR}uploadScanResults.sh ) &", 5)

        elif ps=="/upload_results":
            out_html, err_at_exec = run_in_background(True, "uploadScanResults.sh", 1)

        elif ps=="/reboot":
            out_html, err_at_exec = run_in_background(True, "stopBgScanLoop.sh", 1)
            out_html, err_at_exec = run_and_get_output(False, 'sudo shutdown --reboot +1 "reboot from local web control"', 5)
            print('executed: sudo shutdown --reboot +1')

        elif ps=="/shutdown":
            out_html, err_at_exec = run_in_background(True, "stopBgScanLoop.sh", 1)
            out_html, err_at_exec = run_and_get_output(False, 'sudo shutdown --poweroff +1 "poweroff from local web control"', 5)
            print('executed: sudo shutdown --poweroff +1')

        elif ps=="/config_pwd":
            out_html, err_at_exec = self.POST_config_pwd(d)

        elif ps=="/logout":
            if loggedIn:
                del SESSIONS[session]
                out_html = "<p>Logout successful.</p>"
            else:
                out_html = "<p>Error: You were not logged in.</p>"

        else:
            err_at_exec = False
            reloadURL = joinURL(ps + ".html", f"session={session}")

        self.send_response(200)
        self.wfile.write(str.encode('<!DOCTYPE html>\n<html lang="en-US">\n'))

        if len(reloadURL) > 0:
            self.wfile.write( HEADstr(f'<meta http-equiv="refresh" content="{reloadTim}; url={reloadURL}">') )
        else:
            self.wfile.write( HEADstr('') )

        self.wfile.write(b'<body>\n')
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
        elif ps=="/config":
            self.wfile.write(str.encode(out_html))
            self.wfile.write(str.encode( f'<p>back to <a href="/config.html?session={session}">configuration</a></p>'))
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
        self.wfile.write(str.encode( f'<p>back to <a href="/index.html?session={session}">menu</a></p>'))

        self.wfile.write(b'</body>')
        self.wfile.write(b'</html>')


def run(server_class=HTTPServer, handler_class=BaseHTTPRequestHandler):
    """ follows example shown on docs.python.org """
    server_address = (HOST_ADDRESS, HOST_PORT)
    httpd = server_class(server_address, handler_class)
    if use_SSL:
        httpd.socket = ssl.wrap_socket (httpd.socket, SSL_key, SSL_cert, server_side=True)
    httpd.serve_forever()

if __name__ == '__main__':
    run(handler_class=RequestHandler)


