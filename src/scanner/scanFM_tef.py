#!/usr/bin/env python3

import os
import re
import signal
import socket
import select
import sys
import time
import subprocess
import hashlib
from datetime import datetime, timezone

try:
    import serial  # type: ignore
except Exception:
    serial = None


def now_iso():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f Z")


def utc_epoch():
    return int(time.time())


def env(name, default=""):
    v = os.environ.get(name)
    if v is None or v == "":
        return default
    return v


def read_gps_inc(path):
    vals = {
        "GPSLAT": "",
        "GPSLON": "",
        "GPSMODE": "",
        "GPSALT": "",
        "GPSTIM": "",
    }
    if not os.path.exists(path):
        return vals
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        for ln in f:
            # Accept both shell formats used in this project:
            # export GPSLAT="..."  and  GPSLAT="..."
            m = re.match(r"\s*(?:export\s+)?([A-Za-z0-9_]+)=(.*)\s*$", ln.strip())
            if not m:
                continue
            k = m.group(1)
            v = m.group(2).strip()
            if len(v) >= 2 and ((v[0] == '"' and v[-1] == '"') or (v[0] == "'" and v[-1] == "'")):
                v = v[1:-1]
            if k in vals:
                vals[k] = v
    return vals


# Global connection reference for signal handler
_tef_conn_global = None


def _signal_handler(sig, frame):
    """Handle Ctrl+C and other signals to stop scanning and cleanup."""
    global _tef_conn_global
    if _tef_conn_global is not None:
        try:
            _tef_conn_global.stop_scan()
        except Exception:
            pass
    sys.exit(1)


class TefConn:
    def __init__(self):
        self.transport = env("FMLIST_TEF_TRANSPORT", "serial").lower()
        self.sock = None
        self.ser = None

    def open(self):
        if self.transport == "tcp":
            host = env("FMLIST_TEF_TCP_HOST", "192.168.1.50")
            port = int(env("FMLIST_TEF_TCP_PORT", "7373"))
            self.sock = socket.create_connection((host, port), timeout=2.0)
            self._tcp_auth_if_needed()
            self.sock.settimeout(0.5)
            return

        if serial is None:
            raise RuntimeError("pyserial is required for FMLIST_TEF_TRANSPORT=serial")
        port = env("FMLIST_TEF_SERIAL_PORT", "/dev/ttyUSB0")
        baud = int(env("FMLIST_TEF_SERIAL_BAUD", "115200"))
        try:
            self.ser = serial.Serial(port, baudrate=baud, timeout=0.5)
        except serial.SerialException as ex:
            raise RuntimeError(f"Serial port {port} is busy or unavailable: {ex}. "
                             f"Check: lsof {port} (Linux) or Mode COM Ports (Windows). "
                             f"If xdr-gtk is running, close it first.")

    def handshake(self):
        """Send initialization sequence: 'x' command and wait for 'OK' response."""
        self.write("x")
        lines = self.read_lines(1.0)
        for ln in lines:
            if "OK" in ln or ln == "OK":
                return True
        raise RuntimeError(f"TEF handshake failed: no 'OK' response after 'x' command")

    def _tcp_auth_if_needed(self):
        """Optional xdr-gtk TCP auth: recv salt, send sha1(salt+password)."""
        if self.sock is None:
            return
        mode = env("FMLIST_TEF_TCP_AUTH", "none").strip().lower()
        if mode in ("", "none", "off", "0", "false"):
            return
        if mode not in ("xdr", "xdr-gtk"):
            raise RuntimeError(f"Unsupported FMLIST_TEF_TCP_AUTH mode: {mode}")

        password = env("FMLIST_TEF_TCP_PASSWORD", "")
        prev_timeout = self.sock.gettimeout()
        try:
            self.sock.settimeout(5.0)
            salt = b""
            while len(salt) < 17:
                chunk = self.sock.recv(17 - len(salt))
                if not chunk:
                    break
                salt += chunk
            if len(salt) != 17:
                raise RuntimeError("TCP auth failed: did not receive 17-byte salt line")
            salt_raw = salt[:16]
            digest = hashlib.sha1(salt_raw + password.encode("utf-8")).hexdigest()
            self.sock.sendall((digest + "\n").encode("ascii"))
        finally:
            self.sock.settimeout(prev_timeout)

    def stop_scan(self):
        """Stop active spectrum scan on the TEF6686."""
        try:
            self.write("E")
            self.read_lines(0.15)
        except Exception:
            pass

    def close(self):
        try:
            self.stop_scan()
        except Exception:
            pass
        if self.sock is not None:
            self.sock.close()
            self.sock = None
        if self.ser is not None:
            self.ser.close()
            self.ser = None

    def write(self, cmd):
        line = (cmd + "\n").encode("ascii", errors="ignore")
        if self.sock is not None:
            self.sock.sendall(line)
        elif self.ser is not None:
            self.ser.write(line)
        else:
            raise RuntimeError("TEF connection is not open")

    def read_lines(self, seconds, idle_break_after_data_sec=None):
        end = time.time() + seconds
        buff = b""
        out = []
        last_data = time.time()
        while time.time() < end:
            chunk = b""
            try:
                if self.sock is not None:
                    chunk = self.sock.recv(4096)
                elif self.ser is not None:
                    chunk = self.ser.read(4096)
            except Exception:
                chunk = b""
            if not chunk:
                # Optional idle-based early exit after at least one line was received.
                if idle_break_after_data_sec is not None and out and (time.time() - last_data) > idle_break_after_data_sec:
                    break
                continue
            last_data = time.time()
            buff += chunk
            while b"\n" in buff:
                ln, buff = buff.split(b"\n", 1)
                txt = ln.decode("utf-8", errors="ignore").strip()
                if txt:
                    out.append(txt)
        return out

    def clear_input(self):
        """Drop pending bytes so next capture starts with fresh tuner output."""
        try:
            if self.ser is not None:
                self.ser.reset_input_buffer()
        except Exception:
            pass

        if self.sock is not None:
            prev_timeout = None
            try:
                prev_timeout = self.sock.gettimeout()
                self.sock.settimeout(0.0)
                while True:
                    chunk = self.sock.recv(4096)
                    if not chunk:
                        break
            except Exception:
                pass
            finally:
                try:
                    self.sock.settimeout(prev_timeout)
                except Exception:
                    pass


def parse_scan_pairs(lines):
    """Parse TEF scan output. Format: U87500 = 39, 87600 = 57, ..."""
    pairs = []
    for ln in lines:
        if not ln.strip().startswith('U'):
            continue
        # Remove 'U' prefix and split by comma
        content = ln.strip()[1:]
        parts = content.split(',')
        for part in parts:
            # Format: "87500 = 39" or "87500=39"
            m = re.match(r'\s*(\d+)\s*=\s*([\d.]+)', part.strip())
            if m:
                freq_khz = int(m.group(1))
                power_db = float(m.group(2))
                # Convert kHz to Hz
                freq_hz = freq_khz * 1000
                pairs.append((freq_hz, power_db))
    return pairs


def parse_rds_fields(lines):
    txt = "\n".join(lines)
    pi = ""
    ps = ""

    m_pi = re.search(r'"pi"\s*:\s*"?(0x[0-9A-Fa-f]+|[0-9A-Fa-f]{4})"?', txt)
    if m_pi:
        pi = m_pi.group(1).replace("0x", "").upper()

    m_ps = re.search(r'"ps"\s*:\s*"([^\"]+)"', txt)
    if m_ps:
        ps = collapse_empty_ps(normalize_ps_text(m_ps.group(1)))

    return pi, ps


def normalize_ps_text(ps):
    if ps is None:
        return ""
    v = str(ps).replace(",", " ")
    # PS is always 8 chars; pad before replacing spaces so trailing blanks become underscores too.
    v = v[:8].ljust(8)
    return v.replace(" ", "_")


def collapse_empty_ps(ps):
    """Treat all-blank PS marker as empty so no-RDS frequencies do not persist ________."""
    return "" if ps == "________" else ps


def _decode_udp_hex_ascii(hex_str):
    raw = (hex_str or "").strip()
    if not raw:
        return ""
    if len(raw) % 2 == 1:
        raw = raw[:-1]
    out = []
    for i in range(0, len(raw), 2):
        try:
            b = int(raw[i:i + 2], 16)
        except Exception:
            continue
        if b == 0:
            continue
        out.append(chr(b if 32 <= b <= 126 else 32))
    return "".join(out)


def _decode_udp_af_hex(hex_str):
    raw = (hex_str or "").strip()
    if not raw:
        return ""
    if len(raw) % 2 == 1:
        raw = raw[:-1]
    out = []
    for i in range(0, len(raw), 2):
        try:
            code = int(raw[i:i + 2], 16)
        except Exception:
            continue
        if code <= 0:
            continue
        f10 = 8750 + (code * 10)
        out.append(f"{f10 / 100.0:.1f}")
    return ";".join(out)


def _parse_udp_freq_to_hz(freq_txt):
    txt = (freq_txt or "").strip()
    if not txt:
        return None
    txt = txt.replace("MHz", "").replace("mhz", "").strip()
    try:
        if "." in txt:
            return int(round(float(txt) * 1_000_000.0))
        v = int(txt)
        if v < 1000:
            return int(v * 1_000_000)
        if v < 100000:
            return int(v * 10_000)
        if v < 1_000_000:
            return int(v * 1_000)
        return v
    except Exception:
        return None


class UdpRdsCollector:
    def __init__(self):
        self.enabled = env("FMLIST_TEF_UDP_ENABLE", "1") != "0"
        self.bind_host = env("FMLIST_TEF_UDP_BIND", "0.0.0.0")
        self.port_9030 = int(env("FMLIST_TEF_UDP_PORT_9030", "9030"))
        self.port_9100 = int(env("FMLIST_TEF_UDP_PORT_9100", "9100"))
        self.socks = []
        self.by_freq = {}
        self.last_line_by_freq = {}

    def open(self):
        if not self.enabled:
            return
        for port in (self.port_9030, self.port_9100):
            try:
                s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                s.bind((self.bind_host, port))
                s.setblocking(False)
                self.socks.append(s)
            except Exception:
                continue

    def close(self):
        for s in self.socks:
            try:
                s.close()
            except Exception:
                pass
        self.socks = []

    def poll(self, seconds=0.0):
        if not self.socks:
            return
        end = time.time() + max(0.0, float(seconds))
        while True:
            timeout = 0.0
            if seconds > 0.0:
                timeout = max(0.0, end - time.time())
                if timeout <= 0.0:
                    break
            try:
                ready, _, _ = select.select(self.socks, [], [], timeout)
            except Exception:
                break
            if not ready:
                break
            for s in ready:
                while True:
                    try:
                        payload, _addr = s.recvfrom(4096)
                    except BlockingIOError:
                        break
                    except Exception:
                        break
                    txt = payload.decode("utf-8", errors="ignore").strip()
                    if not txt:
                        continue
                    self._ingest(txt, s.getsockname()[1])
            if seconds <= 0.0:
                break

    def _merge(self, freq_hz, update):
        if freq_hz is None:
            return
        cur = self.by_freq.get(freq_hz, {})
        for k, v in update.items():
            if v:
                cur[k] = v
        cur["ts"] = time.time()
        self.by_freq[freq_hz] = cur

    def _remember_last_line(self, freq_hz, line, local_port):
        if freq_hz is None:
            return
        self.last_line_by_freq[freq_hz] = {
            "ts": time.time(),
            "port": local_port,
            "line": line,
        }

    def _ingest(self, txt, local_port):
        if local_port == self.port_9100:
            self._ingest_9100(txt)
            return
        self._ingest_9030(txt)

    def _ingest_9100(self, txt):
        # UDP 9100 row: CHIP,VERSION,SCANMODE,DATE,TIME,UTC,FREQ,PI,SIGNAL,...,PS,RT,AF,...
        parts = [p.strip() for p in txt.split(",")]
        if len(parts) < 12:
            return

        freq_idx = -1
        freq_hz = None
        for i in range(4, min(len(parts), 11)):
            cand = _parse_udp_freq_to_hz(parts[i])
            if cand is not None and 60_000_000 <= cand <= 200_000_000:
                freq_hz = cand
                freq_idx = i
                break
        if freq_hz is None:
            return

        ps_idx = freq_idx + 10
        rt_idx = freq_idx + 11
        af_idx = freq_idx + 12
        ps = collapse_empty_ps(normalize_ps_text(parts[ps_idx])) if len(parts) > ps_idx else ""
        rt = parts[rt_idx] if len(parts) > rt_idx else ""
        af = parts[af_idx] if len(parts) > af_idx else ""
        self._merge(freq_hz, {"ps": ps, "rt": rt, "af": af, "src": "udp9100"})
        self._remember_last_line(freq_hz, txt, self.port_9100)

    def _ingest_9030(self, txt):
        if ";" not in txt or "=" not in txt:
            return
        fields = {}
        for part in txt.split(";"):
            if "=" not in part:
                continue
            k, v = part.split("=", 1)
            fields[k.strip().upper()] = v.strip()

        freq_hz = None
        for key in ("FREQ", "FREQUENCY", "FRQ"):
            if key in fields:
                freq_hz = _parse_udp_freq_to_hz(fields.get(key))
                if freq_hz is not None:
                    break
        if freq_hz is None:
            return

        ps = ""
        if "PS" in fields:
            ps = collapse_empty_ps(normalize_ps_text(_decode_udp_hex_ascii(fields.get("PS", ""))))
        rt = ""
        if "RT1" in fields:
            rt = _decode_udp_hex_ascii(fields.get("RT1", ""))
        af = ""
        if "AF" in fields:
            af = _decode_udp_af_hex(fields.get("AF", ""))

        self._merge(freq_hz, {"ps": ps, "rt": rt, "af": af, "src": "udp9030"})
        self._remember_last_line(freq_hz, txt, self.port_9030)

    def get_for_freq(self, freq_hz, max_age_sec):
        if freq_hz not in self.by_freq:
            return {}
        rec = self.by_freq.get(freq_hz, {})
        if (time.time() - rec.get("ts", 0)) > max_age_sec:
            return {}
        return dict(rec)

    def pop_last_line_for_freq(self, freq_hz, max_age_sec):
        rec = self.last_line_by_freq.pop(freq_hz, None)
        if not rec:
            return None
        if (time.time() - rec.get("ts", 0)) > max_age_sec:
            return None
        return rec


def read_rdscols_from_redsea_txt(redsea_txt_path):
    """Use the same converter as RTL path to keep fm_rds CSV column parity."""
    script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "redsea.json2csv.sh")
    if not os.path.exists(script):
        return ""
    try:
        proc = subprocess.run(
            ["bash", script, redsea_txt_path],
            capture_output=True,
            text=True,
            timeout=5.0,
            check=False,
        )
    except Exception:
        return ""
    if proc.returncode != 0:
        return ""
    return proc.stdout.strip()


def build_rdscols_fallback(pi, ps):
    """Return RTL-compatible RDSCOLS shape when converter script is unavailable."""
    # redsea.json2csv.sh emits:
    # PI,NPI,PS,NPS,TA,TP,MUSIC,PTY,GRP,STEREO,DYNPTY,OTHER_PI,,,,,,AF,RT,APS,longPS
    cols = [
        pi,   # PI
        "",   # NPI
        ps,   # PS
        "",   # NPS
        "",   # TA
        "",   # TP
        "",   # MUSIC
        "",   # PTY
        "",   # GRP
        "",   # STEREO
        "",   # DYNPTY
        "",   # OTHER_PI
        "", "", "", "", "", "",  # reserved/unused columns
        "",   # AF
        "",   # RT
        "",   # APS
        "",   # longPS
    ]
    return ",".join(cols)


def normalize_rdscols_width(rdscols, expected_fields=22):
    """Ensure TEF RDSCOLS always has the same width as redsea.json2csv.sh output."""
    parts = rdscols.split(",") if rdscols is not None else []
    if len(parts) < expected_fields:
        parts.extend([""] * (expected_fields - len(parts)))
    elif len(parts) > expected_fields:
        parts = parts[:expected_fields]
    return ",".join(parts)


def csv_quote_field(value):
    txt = "" if value is None else str(value)
    if txt == "":
        return ""
    if len(txt) >= 2 and txt[0] == '"' and txt[-1] == '"':
        txt = txt[1:-1]
    txt = txt.replace('"', '""')
    return f'"{txt}"'


def csv_quote_alnum_field(value):
    txt = "" if value is None else str(value).strip()
    if txt == "":
        return ""
    if re.fullmatch(r"[+-]?\d+(?:\.\d+)?", txt):
        return txt
    return csv_quote_field(txt)


def format_semicolon_mixed_field(value):
    """Quote alnum tokens in ; separated payload, keep numeric and empty tokens raw."""
    txt = "" if value is None else str(value).strip()
    if txt == "":
        return ""
    out = []
    for tok in txt.split(";"):
        t = tok.strip()
        if t == "":
            out.append("")
        elif re.fullmatch(r"[+-]?\d+(?:\.\d+)?", t):
            out.append(t)
        else:
            out.append(csv_quote_field(t))
    return ";".join(out)


def format_eon_field(value):
    """Format EON payload (PI;PS;MF1;MF2;MF3 groups), keeping PI unquoted."""
    txt = "" if value is None else str(value).strip()
    if txt == "":
        return ""
    toks = txt.split(";")
    out = []
    for i, tok in enumerate(toks):
        t = tok.strip()
        if t == "":
            out.append("")
            continue
        # First token of each 5-field EON group is PI; keep it unquoted.
        if (i % 5) == 0:
            out.append(t)
            continue
        if re.fullmatch(r"[+-]?\d+(?:\.\d+)?", t):
            out.append(t)
        else:
            out.append(csv_quote_field(t))
    return ";".join(out)


def normalize_eon_ps_tokens(value):
    """EON payload groups are PI;PS;MF1;MF2;MF3. Normalize PS tokens only."""
    txt = "" if value is None else str(value).strip()
    if txt == "":
        return ""
    toks = txt.split(";")
    for i in range(len(toks)):
        # In each 5-token EON group, token index 1 is PS.
        if (i % 5) == 1 and toks[i] != "":
            toks[i] = normalize_ps_text(toks[i])
    return ";".join(toks)


def _csv_part(parts, idx):
    if idx < 0 or idx >= len(parts):
        return ""
    return parts[idx].strip()


def format_udp_last_row(epoch, freq_hz, udp_last, include_raw_line=False):
    port = udp_last.get("port", "")
    line = (udp_last.get("line", "") or "").replace("\r", " ").replace("\n", " ")

    # Structured parse for TEF UDP 9100 rows.
    if port == 9100:
        parts = [p.strip() for p in line.split(",")]
        freq_idx = -1
        for i in range(4, min(len(parts), 11)):
            cand = _parse_udp_freq_to_hz(parts[i])
            if cand is not None and 60_000_000 <= cand <= 200_000_000:
                freq_idx = i
                break

        if freq_idx >= 0:
            # TEF 9100 shape after freq is:
            # PI,SIGNAL,STEREO,TA,TP,TMC,PTY,ECC,LIC,PS,RT,AF,EON,RTPLUS
            # RT may contain commas, so parse AF/EON/RTPLUS from the right.
            n = len(parts)
            if n < (freq_idx + 15):
                pass
            else:
                chip = _csv_part(parts, 0)
                version = _csv_part(parts, 1)
                scandx = _csv_part(parts, 2)
                date = _csv_part(parts, 3)
                tim = _csv_part(parts, 4)
                utc = _csv_part(parts, 5)
                freq_txt = _csv_part(parts, freq_idx)
                pi = _csv_part(parts, freq_idx + 1)
                signal = _csv_part(parts, freq_idx + 2)
                stereo = _csv_part(parts, freq_idx + 3)
                ta = _csv_part(parts, freq_idx + 4)
                tp = _csv_part(parts, freq_idx + 5)
                tmc = _csv_part(parts, freq_idx + 6)
                pty = _csv_part(parts, freq_idx + 7)
                ecc = _csv_part(parts, freq_idx + 8)
                lic = _csv_part(parts, freq_idx + 9)
                ps = _csv_part(parts, freq_idx + 10)

                eon = _csv_part(parts, n - 2)
                af = _csv_part(parts, n - 3)
                rt_start = freq_idx + 11
                rt_end = n - 3
                rt = ""
                if rt_end > rt_start:
                    rt = ",".join([p.strip() for p in parts[rt_start:rt_end]])

                cols = [
                    str(epoch),
                    "freq",
                    str(freq_hz),
                    str(port),
                    csv_quote_alnum_field(chip),
                    csv_quote_alnum_field(version),
                    scandx,
                    date,
                    tim,
                    utc,
                    freq_txt,
                    pi,
                    csv_quote_alnum_field(signal),
                    stereo,
                    ta,
                    tp,
                    tmc,
                    pty,
                    csv_quote_alnum_field(ecc),
                    csv_quote_alnum_field(lic),
                    csv_quote_field(ps) if ps != "" else "",
                    csv_quote_alnum_field(rt),
                    csv_quote_field(af) if af != "" else "",
                    format_eon_field(normalize_eon_ps_tokens(eon)),
                ]
                if include_raw_line:
                    cols.append(csv_quote_field(line))
                return ",".join(cols)

    # Fallback/raw rows (e.g. 9030): keep payload in udp_line column.
    cols = [
        str(epoch), "freq", str(freq_hz), str(port),
        "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
    ]
    if include_raw_line:
        cols.append(csv_quote_field(line))
    return ",".join(cols)


def merge_udp_into_rdscols(rdscols, pi, ps, af, rt):
    merged = normalize_rdscols_width(rdscols)
    parts = merged.split(",")

    # Keep text-field parity with redsea style: PS/RT should be quoted in CSV when present.
    if parts[2] != "":
        parts[2] = csv_quote_field(parts[2])
    if parts[19] != "":
        parts[19] = csv_quote_field(parts[19])

    if pi:
        parts[0] = pi
    if ps:
        parts[2] = csv_quote_field(ps)
    if af:
        parts[18] = af
    if rt:
        parts[19] = csv_quote_field(rt)
    return ",".join(parts)


def decode_rds_with_redsea(tef_lines, timeout_sec):
    """Decode TEF6686 lines with redsea in two stages (tef->hex, hex->json)."""
    if not tef_lines:
        return [], []

    tef_input = "\n".join(tef_lines) + "\n"
    # Stage 1: parse TEF stream and emit RDS Spy compatible hex lines.
    cmd_hex = [
        "redsea",
        "-p",
        "--bler",
        "--output-hex",
        "--timestamp",
        "@%Y/%m/%d %T",
        "-i",
        "tef",
    ]

    # Stage 2: decode that hex stream to JSON lines.
    cmd_json = ["redsea", "-p", "--input-hex"]

    try:
        proc_hex = subprocess.run(
            cmd_hex,
            input=tef_input,
            capture_output=True,
            text=True,
            timeout=max(2.0, timeout_sec + 2.0),
            check=False,
        )
    except FileNotFoundError:
        return [], []
    except Exception:
        return [], []

    spy_lines = []
    if proc_hex.stdout:
        for ln in proc_hex.stdout.splitlines():
            txt = ln.strip()
            if txt:
                spy_lines.append(txt)

    # Skip groups where blocks B/C/D are all missing (----), they carry no useful RDS payload.
    filtered_spy_lines = []
    for ln in spy_lines:
        pre = ln.split("@", 1)[0].strip()
        parts = pre.split()
        if len(parts) >= 4 and parts[1] == "----" and parts[2] == "----" and parts[3] == "----":
            continue
        filtered_spy_lines.append(ln)

    if not filtered_spy_lines:
        return [], []

    spy_input = "\n".join(filtered_spy_lines) + "\n"
    try:
        proc_json = subprocess.run(
            cmd_json,
            input=spy_input,
            capture_output=True,
            text=True,
            timeout=max(2.0, timeout_sec + 2.0),
            check=False,
        )
    except Exception:
        return spy_lines, []

    json_lines = []
    if proc_json.stdout:
        for ln in proc_json.stdout.splitlines():
            txt = ln.strip()
            if txt:
                json_lines.append(txt)
    return filtered_spy_lines, json_lines


def trim_to_current_tune(tef_lines, freq_khz):
    """Discard stale lines from previous frequency and start at current T marker."""
    marker = f"T{freq_khz}"
    start_idx = -1
    for i, ln in enumerate(tef_lines):
        if ln == marker or ln.startswith(marker):
            start_idx = i
    if start_idx >= 0:
        return tef_lines[start_idx:]
    return tef_lines


def append_line(path, line):
    with open(path, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def write_last(ram_dir, freq_hz, pi, ps):
    last_key = f"FM {freq_hz}"
    last_info = f"{pi} {ps}".strip()
    with open(os.path.join(ram_dir, "LAST"), "w", encoding="utf-8") as f:
        f.write(last_key + "\n")
    with open(os.path.join(ram_dir, "LAST.info"), "w", encoding="utf-8") as f:
        f.write(last_info + "\n")

    hist = os.path.join(ram_dir, "LAST.history")
    prev = []
    if os.path.exists(hist):
        with open(hist, "r", encoding="utf-8", errors="ignore") as f:
            prev = [ln.rstrip("\n") for ln in f if not ln.startswith(last_key + " ")]
    prev.append((last_key + " " + last_info).strip())
    prev = prev[-50:]
    with open(hist, "w", encoding="utf-8") as f:
        for ln in prev:
            f.write(ln + "\n")


def auto_threshold(pairs, margin_db=15.0):
    """Estimate noise floor from spectrum (25th percentile) and add margin."""
    if not pairs:
        return 35.0
    powers = sorted(p for (_, p) in pairs)
    # 25th percentile = upper edge of the quietest quarter of the band
    idx = max(0, len(powers) // 4 - 1)
    noise_floor = powers[idx]
    return noise_floor + margin_db


def main():
    global _tef_conn_global
    
    # Setup signal handlers to gracefully stop TEF scan on interrupt
    signal.signal(signal.SIGINT, _signal_handler)
    signal.signal(signal.SIGTERM, _signal_handler)
    
    home = os.path.expanduser("~")
    ram_dir = env("FMLIST_SCAN_RAM_DIR", f"/dev/shm/{env('FMLIST_SCAN_USER', 'pi')}_fmlist_scan")
    os.makedirs(ram_dir, exist_ok=True)

    dtfrec = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H%M%S")
    rec_name = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] else f"scan_{dtfrec}_FM"
    rec_path = os.path.join(ram_dir, rec_name)
    # rec_path directory is created only after spectrum scan completes (see below)

    t_beg = utc_epoch()
    dt_start = now_iso()

    gps = read_gps_inc(os.path.join(ram_dir, "gpscoor.inc"))
    gps_cols = ",".join([
        gps.get("GPSLAT", ""),
        gps.get("GPSLON", ""),
        gps.get("GPSMODE", ""),
        gps.get("GPSALT", ""),
        gps.get("GPSTIM", ""),
    ])

    pos = env("FMLIST_UP_POSITION", "").lower()
    dwell_mobile = int(env("FMLIST_TEF_DWELL_MOBILE_SEC", "5"))
    dwell_fixed = int(env("FMLIST_TEF_DWELL_FIXED_SEC", "10"))
    dwell = dwell_mobile if pos == "mobile" else dwell_fixed

    threshold_cfg = env("FMLIST_TEF_SCAN_THRESHOLD_DB", "").strip()
    auto_threshold_mode = not threshold_cfg or threshold_cfg.lower() == "auto"
    threshold = None if auto_threshold_mode else float(threshold_cfg)
    threshold_margin = float(env("FMLIST_TEF_SCAN_THRESHOLD_MARGIN_DB", "15"))
    beg_hz = int(env("FMLIST_TEF_SCAN_SAVE_MINFREQ", env("FMLIST_SCAN_SAVE_MINFREQ", "87500000")))
    end_hz = int(env("FMLIST_TEF_SCAN_SAVE_MAXFREQ", env("FMLIST_SCAN_SAVE_MAXFREQ", "108000000")))
    step_hz = 100000
    debug_enabled = env("FMLIST_SCAN_DEBUG", "0") != "0"

    conn = TefConn()
    _tef_conn_global = conn
    udp = UdpRdsCollector()
    try:
        conn.open()
        conn.handshake()
        udp.open()
    except Exception as ex:
        append_line(os.path.join(ram_dir, "scanner.log"), f"FM scan failed to initialize TEF: {ex}")
        print(f"FM scan failed to initialize TEF: {ex}")
        return 1

    try:
        start_khz = beg_hz // 1000
        stop_khz = end_hz // 1000
        step_khz = step_hz // 1000

        sweep_ms = int(env("FMLIST_TEF_SWEEP_MS", "10"))
        n_steps = (stop_khz - start_khz) // step_khz + 1
        # Timeout: full sweep duration + 3 s overhead, minimum 12 s.
        sweep_timeout = max(12.0, n_steps * sweep_ms / 1000.0 + 3.0)

        # Retry the spectrum sweep until we receive the expected number of frequency/power
        # pairs.  The TEF can output Sm/Ss (signal-meter / seek) lines instead of the
        # U-prefixed scan lines when it hasn't yet processed the Sa/Sb/Sc/Sw parameters
        # (e.g. due to buffered output from the previous tune).  In that case pairs will
        # be empty or incomplete and we simply restart the sweep.
        MAX_SWEEP_TRIES = 3
        pairs = []
        scan_lines = []
        for sweep_try in range(1, MAX_SWEEP_TRIES + 1):
            conn.stop_scan()
            conn.clear_input()

            conn.write(f"Sa{start_khz}")
            conn.write(f"Sb{stop_khz}")
            conn.write(f"Sc{step_khz}")
            conn.write(f"Sw{sweep_ms}")
            conn.write("S")

            # Read until a short idle period — the full sweep completes well within
            # sweep_timeout; idle_break avoids unnecessary waiting after the last line.
            scan_lines = conn.read_lines(sweep_timeout, idle_break_after_data_sec=0.3)

            # Stop continuous scan loop so the TEF returns to normal tuner mode.
            conn.stop_scan()

            pairs = parse_scan_pairs(scan_lines)
            if len(pairs) >= n_steps:
                # Full spectrum received.
                break
            # Incomplete — log and retry after a short settle delay.
            if sweep_try < MAX_SWEEP_TRIES:
                append_line(os.path.join(ram_dir, "scanner.log"),
                            f"Spectrum sweep incomplete (try {sweep_try}/{MAX_SWEEP_TRIES}): "
                            f"got {len(pairs)}/{n_steps} pairs — retrying")
                time.sleep(1.0)

        if not pairs:
            # Fallback: tune over raster and infer rough level from any numeric replies.
            pairs = []
            for f in range(beg_hz, end_hz + 1, step_hz):
                conn.write(f"T{f // 1000}")
                lines = conn.read_lines(0.15)
                p = -999.0
                for ln in lines:
                    nums = re.findall(r"-?\d+(?:\.\d+)?", ln)
                    if nums:
                        p = float(nums[-1])
                pairs.append((f, p))

        if auto_threshold_mode:
            threshold = auto_threshold(pairs, threshold_margin)
            powers = sorted(p for (_, p) in pairs)
            noise_floor = powers[max(0, len(powers) // 4 - 1)] if powers else 0

        selected = [(f, p) for (f, p) in pairs if p >= threshold and f >= beg_hz and f <= end_hz]
        selected.sort(key=lambda x: x[0])

        # Tune to the first selected frequency BEFORE doing any file I/O so the TEF
        # is already receiving while we write debug files.  TCP buffers the dwell data.
        first_tune_sent = False
        if selected:
            conn.clear_input()
            conn.write(f"T{selected[0][0] // 1000}")
            first_tune_sent = True

        # --- file I/O (TEF already tuning in background) ---
        os.makedirs(rec_path, exist_ok=True)
        append_line(os.path.join(rec_path, "scan_duration.txt"), f"FM scan started at {dt_start}")
        append_line(os.path.join(rec_path, "scan_duration.txt"),
                   f"Scan returned {len(scan_lines)} lines (sweep attempt {sweep_try}/{MAX_SWEEP_TRIES})")

        # Debug-only: save a sample of raw TEF scan output
        if debug_enabled:
            raw_scan_file = os.path.join(rec_path, "scan_raw.txt")
            with open(raw_scan_file, "w", encoding="utf-8") as f:
                for i, ln in enumerate(scan_lines[:20]):
                    f.write(f"Line {i}: {repr(ln)}\n")

        append_line(os.path.join(rec_path, "scan_duration.txt"),
                   f"Parsed {len(pairs)} frequency/power pairs from scan")

        # Debug-only: write full spectrum to file
        if debug_enabled and pairs:
            pairs_sorted = sorted(pairs, key=lambda x: x[1], reverse=True)
            spectrum_file = os.path.join(rec_path, "spectrum_full.csv")
            with open(spectrum_file, "w", encoding="utf-8") as f:
                f.write("freq_mhz,power_db\n")
                for (freq_hz, power) in pairs_sorted:
                    f.write(f"{freq_hz/1e6:.1f},{power:.1f}\n")
            top_20 = ", ".join([f"{f/1e6:.1f}({p:.1f}dB)" for (f, p) in pairs_sorted[:20]])
            append_line(os.path.join(rec_path, "scan_duration.txt"),
                       f"Top 20 by power: {top_20}")

        if auto_threshold_mode:
            append_line(os.path.join(rec_path, "scan_duration.txt"),
                       f"Auto threshold: noise floor ~{noise_floor:.1f}dB + {threshold_margin:.0f}dB margin = {threshold:.1f}dB")

        # Show what was filtered
        filtered_out = [(f, p) for (f, p) in pairs if p < threshold and f >= beg_hz and f <= end_hz]
        if filtered_out:
            filtered_sorted = sorted(filtered_out, key=lambda x: x[1], reverse=True)
            top_filtered = ", ".join([f"{f/1e6:.1f}({p:.1f}dB)" for (f, p) in filtered_sorted[:10]])
            append_line(os.path.join(rec_path, "scan_duration.txt"),
                       f"Filtered out (below {threshold:.1f}dB): {top_filtered}")

        append_line(os.path.join(rec_path, "scan_duration.txt"),
                   f"Threshold {threshold:.1f}dB: selected {len(selected)} frequencies from {beg_hz/1e6:.1f}\u2013{end_hz/1e6:.1f} MHz")
        if selected:
            first_10 = ", ".join([f"{f/1e6:.1f}({p:.1f}dB)" for (f, p) in selected[:10]])
            append_line(os.path.join(rec_path, "scan_duration.txt"),
                       f"Top 10 selected: {first_10}")

        udp_last_file = os.path.join(rec_path, "udp_last_by_freq.csv")
        udp_include_raw = env("FMLIST_TEF_UDP_LOG_RAW_LINE", "0") == "1"
        if udp_include_raw:
            append_line(udp_last_file, "epoch,kind,freq_hz,udp_port,chip,version,scandxmode,date,time,utc,freq,pi,signal,stereo,ta,tp,tmc,pty,ecc,lic,ps,rt,af,eon,udp_line")
        else:
            append_line(udp_last_file, "epoch,kind,freq_hz,udp_port,chip,version,scandxmode,date,time,utc,freq,pi,signal,stereo,ta,tp,tmc,pty,ecc,lic,ps,rt,af,eon")

        for i, (freq_hz, power) in enumerate(selected):
            dt = now_iso()
            epoch = utc_epoch()
            freq_khz = freq_hz // 1000
            if i == 0 and first_tune_sent:
                # T was already sent before file I/O; TCP has buffered the dwell data.
                # Do NOT call clear_input here — that would discard the buffered lines.
                pass
            else:
                conn.clear_input()
                conn.write(f"T{freq_khz}")
            tef_lines = conn.read_lines(float(dwell))
            tef_lines = trim_to_current_tune(tef_lines, freq_khz)
            # Drain UDP 9030/9100 after tune; frequency filtering below rejects delayed packets from prior channels.
            udp.poll(float(env("FMLIST_TEF_UDP_SETTLE_SEC", "1.2")))
            udp_max_age_sec = float(env("FMLIST_TEF_UDP_MAX_AGE_SEC", "6.0"))
            udp_rec = udp.get_for_freq(freq_hz, udp_max_age_sec)
            udp_last = udp.pop_last_line_for_freq(freq_hz, udp_max_age_sec)
            if udp_last is not None:
                append_line(udp_last_file, format_udp_last_row(epoch, freq_hz, udp_last, include_raw_line=udp_include_raw))

            redsea_spy_lines, redsea_lines = decode_rds_with_redsea(tef_lines, float(dwell))

            # Keep RTL naming parity: mark frequencies with no decoded JSON as "_noRDS".
            has_rds_json = len(redsea_lines) > 0
            if has_rds_json:
                redsea_spy = os.path.join(rec_path, f"redsea.{freq_hz}.spy")
                redsea_txt = os.path.join(rec_path, f"redsea.{freq_hz}.txt")
            else:
                redsea_spy = os.path.join(rec_path, f"redsea.{freq_hz}_noRDS.spy")
                redsea_txt = os.path.join(rec_path, f"redsea.{freq_hz}_noRDS.txt")

            with open(redsea_spy, "w", encoding="utf-8") as f:
                for ln in redsea_spy_lines:
                    f.write(ln + "\n")

            with open(redsea_txt, "w", encoding="utf-8") as f:
                for ln in redsea_lines:
                    f.write(ln + "\n")

            carrier_csv = os.path.join(rec_path, f"fm_carrier.{freq_hz}.csv")
            append_line(carrier_csv, f"{epoch},freq,{freq_hz},0,{int(round(power))},{int(round(power))},{dt},{gps_cols}")

            pi, ps = parse_rds_fields(redsea_lines)
            udp_ps = normalize_ps_text(udp_rec.get("ps", "")) if udp_rec else ""
            udp_af = udp_rec.get("af", "") if udp_rec else ""
            udp_rt = udp_rec.get("rt", "") if udp_rec else ""
            if udp_ps:
                ps = udp_ps

            should_write_rds = has_rds_json or bool(udp_ps or udp_af or udp_rt)
            if should_write_rds:
                rds_csv = os.path.join(rec_path, f"fm_rds.{freq_hz}.csv")
                rdscols = read_rdscols_from_redsea_txt(redsea_txt)
                if rdscols:
                    rdscols = merge_udp_into_rdscols(rdscols, pi, ps, udp_af, udp_rt)
                    append_line(rds_csv, f"{epoch},freq,{freq_hz},1,{int(round(power))},{int(round(power))},{dt},{gps_cols},{rdscols}")
                else:
                    # Fallback with full RDSCOLS width to preserve RTL CSV schema.
                    fallback_rdscols = build_rdscols_fallback(pi, ps)
                    fallback_rdscols = merge_udp_into_rdscols(fallback_rdscols, pi, ps, udp_af, udp_rt)
                    append_line(rds_csv, f"{epoch},freq,{freq_hz},1,{int(round(power))},{int(round(power))},{dt},{gps_cols},{fallback_rdscols}")

            write_last(ram_dir, freq_hz, pi, ps)

    finally:
        udp.close()
        conn.close()

    num_rds = len([x for x in os.listdir(rec_path) if x.startswith("fm_rds.") and x.endswith(".csv")])
    num_car = len([x for x in os.listdir(rec_path) if x.startswith("fm_carrier.") and x.endswith(".csv")])
    t_end = utc_epoch()
    dt_end = now_iso()
    dur = max(0, t_end - t_beg)

    append_line(os.path.join(rec_path, "scan_duration.txt"), f"FM scan finished at {dt_end}")
    append_line(os.path.join(rec_path, "scan_duration.txt"), f"FM scan duration {dur} sec")
    append_line(os.path.join(rec_path, "scan_duration.txt"), f"FM scan found {num_rds} RDS carriers and {max(0, num_car - num_rds)} plain carriers")
    append_line(os.path.join(rec_path, "scan_duration.txt"), "FM scan tef6686 options backend=tef6686")
    # Keep RTL parity so scanDurations.sh can read durations from scanner.log.gz.
    append_line(os.path.join(ram_dir, "scanner.log"), f"FM scan finished at {dt_end}. Duration {dur} sec.")

    print(f"FM scan finished at {dt_end}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
