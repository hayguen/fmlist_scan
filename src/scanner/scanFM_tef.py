#!/usr/bin/env python3

import os
import re
import signal
import socket
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
            self.read_lines(0.5)
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
        ps = m_ps.group(1)
        # Replace commas and each whitespace char with underscores while preserving PS length.
        ps = ps.replace(",", "_")
        ps = re.sub(r"\s", "_", ps)

    return pi, ps


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
    try:
        conn.open()
        conn.handshake()
    except Exception as ex:
        append_line(os.path.join(ram_dir, "scanner.log"), f"FM scan failed to initialize TEF: {ex}")
        print(f"FM scan failed to initialize TEF: {ex}")
        return 1

    try:
        start_khz = beg_hz // 1000
        stop_khz = end_hz // 1000
        step_khz = step_hz // 1000

        conn.write(f"Sa{start_khz}")
        conn.write(f"Sb{stop_khz}")
        conn.write(f"Sc{step_khz}")
        conn.write("Sw560")
        conn.write("S")
        
        # Read scan output until short silence to capture complete spectrum without extra wait.
        scan_lines = conn.read_lines(12.0, idle_break_after_data_sec=0.8)

        # Only create the output directory after spectrum scan data has been received
        os.makedirs(rec_path, exist_ok=True)
        append_line(os.path.join(rec_path, "scan_duration.txt"), f"FM scan started at {dt_start}")
        append_line(os.path.join(rec_path, "scan_duration.txt"),
                   f"Scan returned {len(scan_lines)} lines")

        # Debug-only: save a sample of raw TEF scan output
        if debug_enabled:
            raw_scan_file = os.path.join(rec_path, "scan_raw.txt")
            with open(raw_scan_file, "w", encoding="utf-8") as f:
                for i, ln in enumerate(scan_lines[:20]):
                    f.write(f"Line {i}: {repr(ln)}\n")

        pairs = parse_scan_pairs(scan_lines)
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
            append_line(os.path.join(rec_path, "scan_duration.txt"),
                       f"Auto threshold: noise floor ~{noise_floor:.1f}dB + {threshold_margin:.0f}dB margin = {threshold:.1f}dB")

        selected = [(f, p) for (f, p) in pairs if p >= threshold and f >= beg_hz and f <= end_hz]
        selected.sort(key=lambda x: x[0])

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

        for (freq_hz, power) in selected:
            dt = now_iso()
            epoch = utc_epoch()
            freq_khz = freq_hz // 1000
            conn.clear_input()
            conn.write(f"T{freq_khz}")
            tef_lines = conn.read_lines(float(dwell))
            tef_lines = trim_to_current_tune(tef_lines, freq_khz)

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
            if has_rds_json:
                rds_csv = os.path.join(rec_path, f"fm_rds.{freq_hz}.csv")
                rdscols = read_rdscols_from_redsea_txt(redsea_txt)
                if rdscols:
                    rdscols = normalize_rdscols_width(rdscols)
                    append_line(rds_csv, f"{epoch},freq,{freq_hz},1,{int(round(power))},{int(round(power))},{dt},{gps_cols},{rdscols}")
                else:
                    # Fallback with full RDSCOLS width to preserve RTL CSV schema.
                    fallback_rdscols = build_rdscols_fallback(pi, ps)
                    fallback_rdscols = normalize_rdscols_width(fallback_rdscols)
                    append_line(rds_csv, f"{epoch},freq,{freq_hz},1,{int(round(power))},{int(round(power))},{dt},{gps_cols},{fallback_rdscols}")

            write_last(ram_dir, freq_hz, pi, ps)

    finally:
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
