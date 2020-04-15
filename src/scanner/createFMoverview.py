#!/usr/bin/env python3

import sys
import os
import csv
from pathlib import Path

#print(len(sys.argv))
emptyPStext = "(__no_PS__)"

# read .csv (from compareFM.sh) into dictionary with tuple (freq, PI)
# with values count and dictionary over PS
def read(fn):
    global emptyPStext
    d = dict()
    with open(fn) as csvfile:
        rd = csv.reader(csvfile)
        for row in rd:
            #print(len(row), row[0], row[1])
            k = ( row[0], row[1] )
            if k in d.keys():
                v = d[k]
            else:
                v = ( 0, dict() )
            n = v[0] + 1
            dps = v[1]  # dict over ps
            if 2 < len(row):
                ps = row[2]
                if len(ps) <= 0:
                    ps = emptyPStext
            else:
                ps = emptyPStext
            if ps in dps:
                dps[ps] = dps[ps] + 1
            else:
                dps[ps] = 1
            d[ k ] = ( n, dps )
    return d

# print read dictionary in 'human readable' format, easily comparable ..
def printSorted(d, f, num_ps_max):
    global emptyPStext
    for p in range(2):   # 1st pass to collect numbers, 2nd pass prints some details without PS
        nkeys_total = 0
        nkeys_with_ps = 0
        nkeys_empty_ps = 0
        for key, value in d.items():
            nps = value[0]
            dps = value[1]
            if emptyPStext in dps.keys():
                nempty = dps[emptyPStext]
            else:
                nempty = 0
            nwith = nps - nempty

            if p > 0:
                print('', file=f)
                print('{}, {}'.format(key[0], key[1]), file=f)
                print('{}, {}, {}, {}, {}'.format(key[0], key[1], nps, nwith, nempty), file=f)

            if nwith > 0:
                nkeys_with_ps = nkeys_with_ps + 1
            else:
                nkeys_empty_ps = nkeys_empty_ps + 1
            nkeys_total = nkeys_total + 1

        if p <= 0:
            print('total (freq, PI) keys: {}'.format(nkeys_total), file=f)
            print('  with    PS: {}'.format(nkeys_with_ps), file=f)
            print('  without PS: {}'.format(nkeys_empty_ps), file=f)
            print('===========================================', file=f)
            print('freq, PI, #total, #withPS, #noPS', file=f)

    print('===========================================', file=f)
    # print full details - including PS
    print('freq, PI, #total, #PS, PStext', file=f)
    for key, value in d.items():
        dps = value[1]
        print('', file=f)
        print('{}, {}'.format(key[0], key[1]), file=f)
        s = sorted(dps, key=dps.get, reverse=True)[:num_ps_max]
        for k in s:
            print('{}, {}, {}, {}, "{}"'.format(key[0], key[1], value[0], dps[k], k), file=f)


prevDir = os.getcwd()
tempFn = "/dev/shm/cmpFMtemp.txt"
# process every directory argument ..
for argidx in range(1, len(sys.argv)):
    dp = sys.argv[argidx]
    os.chdir(prevDir)
    pth = Path(dp)
    if not pth.is_dir():
        print("skipping dir {}".format(dp))
        continue
    pthabs = pth.resolve() # absolute path
    # str(pthabs.parent)   # absolute path of parent
    # str(pthabs.name)     # last directory

    print("processing directory '{}' ..".format(dp))
    os.chdir( str(pthabs) )
    os.system("cat scan_*_fm_rds.csv | awk -F, '{ OFS=\",\"; print $3,$13,$15; }' |sort -n >" + tempFn)
    print("  shell finished. reading temporary .txt ..")
    dA = read(tempFn)
    outFn = str(pthabs.parent) + "/" + str(pthabs.name) + "_overview.csv"
    print("  writing dictionary to '{}' ..".format(outFn))
    with open( outFn, "w" ) as outFile:
        printSorted(dA, outFile, 3)
        outFile.close()
    print("  finished.")
    os.chdir(prevDir)

tmpf = Path(tempFn)
tmpf.unlink()
os.chdir(prevDir)

