#!/usr/bin/env python3

import subprocess

def get_adapter_infos(adapter :str):
  MAC=""
  IP4=""
  IP6=""

  try:
    out = subprocess.check_output(f"ip a |grep -A 10 ': {adapter}: '", shell=True, universal_newlines=True, timeout=2)
  except:
    out = ""
    return (MAC, IP4, IP6)

  #print("output of ip a is:")
  #print(out)

  lno = 1
  for ln in str(out).split("\n"):
    if lno > 1 and len(ln)>1 and ln[0] != " ":  # got next adapter
      break
    words = ln.split()
    #print(f"{lno}: {ln}")
    #wdno = 1
    #print(f"  {lno}. #words = {len(words)}")
    #for wd in words:
    #  print(f"  {lno}.{wdno}: {wd}")
    #  wdno = wdno + 1
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

#eth0 = get_adapter_infos("eth0")
#print(f"eth0:  MAC = '{eth0[0]}', IP4: '{eth0[1]}', IP6: '{eth0[2]}'")

#wifi = get_adapter_infos("wlan0")
#print(f"wlan0: MAC = '{wifi[0]}', IP4: '{wifi[1]}', IP6: '{wifi[2]}'")


