#!/usr/bin/env python3

import sys, subprocess


if not 1 < len(sys.argv):
    print("usage: get-adapter-info.py <adapter/iface>")
    sys.exit(10)

CMDSTR = ""
ANO=0

for k in range(1, len(sys.argv)):
    adapter = sys.argv[k]
    #print(k, adapter)
    MAC=""
    IP4=""
    IP6=""
    try:
        out = subprocess.check_output(f"ip a |grep -A 10 ': {adapter}: '", shell=True, universal_newlines=True, timeout=2)
    except:
        print(f"Error retrieving parameters of adapter '{adapter}'")
        continue

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

    MACstripped = MAC.replace(":", "")
    if ANO == 0:
        CMDSTR = CMDSTR + f"mac={MACstripped}"
    CMDSTR = CMDSTR + f"&eth{ANO}4={IP4}&eth{ANO}6={IP6}"
    ANO = ANO + 1

print(f"URL:https://i.fmlist.org/urds/geturdsconfig.php?{CMDSTR}")
sys.exit(0)
