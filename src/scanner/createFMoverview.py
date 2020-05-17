#!/usr/bin/env python3

import sys
import os
import csv
from pathlib import Path


numPStoPrint = 3
printPSCounterInc = True
renOverviewFile = False
writeOverviewsCatalog = True

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
def printSorted(d, f, num_ps_max, printPSCounterInc):
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

            if p > 0 and f is not None:
                print('', file=f)
                print('{}, {}'.format(key[0], key[1]), file=f)
                print('{}, {}, 1, {}, {}, {}'.format(key[0], key[1], nps, nwith, nempty), file=f)
                if nwith > 0 and printPSCounterInc:
                    print('{}, {}, 2, "PS counter inc"'.format(key[0], key[1]), file=f)


            if nwith > 0:
                nkeys_with_ps = nkeys_with_ps + 1
            else:
                nkeys_empty_ps = nkeys_empty_ps + 1
            nkeys_total = nkeys_total + 1

        if p <= 0 and f is not None:
            print('total (freq, PI) keys: {}'.format(nkeys_total), file=f)
            print('  with    PS: {}'.format(nkeys_with_ps), file=f)
            print('  without PS: {}'.format(nkeys_empty_ps), file=f)
            print('===========================================', file=f)
            print('freq, PI, rowtype, #total, #withPS, #noPS', file=f)

    if f is not None:
        print('===========================================', file=f)
        # print full details - including PS
        print('freq, PI, rowtype, #total, #PS, PStext', file=f)

        for key, value in d.items():
            dps = value[1]

            nps = value[0]
            if emptyPStext in dps.keys():
                nempty = dps[emptyPStext]
            else:
                nempty = 0
            nwith = nps - nempty

            print('', file=f)
            print('{}, {}'.format(key[0], key[1]), file=f)
            s = sorted(dps, key=dps.get, reverse=True)[:num_ps_max]
            for k in s:
                print('{}, {}, 1, {}, {}, "{}"'.format(key[0], key[1], value[0], dps[k], k), file=f)
            if nwith > 0 and printPSCounterInc:
                print('{}, {}, 2, "PS counter inc"'.format(key[0], key[1]), file=f)

    #print('15, {}, {}, {}'.format(nkeys_total, nkeys_with_ps, nkeys_empty_ps))
    return ( nkeys_total, nkeys_with_ps, nkeys_empty_ps )


prevDir = os.getcwd()
tempFn = "/dev/shm/cmpFMtemp.txt"
writeFiles = True
# process every directory argument ..
for argidx in range(1, len(sys.argv)):
    dp = sys.argv[argidx]
    if dp == "--nowrite":
        writeFiles = False
        continue
    os.chdir(prevDir)
    pth = Path(dp)
    pthabs = pth.resolve() # absolute path
    # str(pthabs.parent)   # absolute path of parent
    # str(pthabs.name)     # last directory

    if pth.is_dir():
        print("processing directory '{}' ..".format(dp))
        os.chdir( str(pthabs) )
        os.system("cat scan_*_fm_rds.csv | awk -F, '{ OFS=\",\"; print $3,$13,$15; }' |sort -n >" + tempFn)
    elif pth.is_file() and dp.endswith("_upload.csv.gz"):
        print("processing .gz compressed .csv file '{}' ..".format(dp))
        awkPrg = '{ OFS=","; print $4, $14,$16; }'
        cmdStr = "zcat '{}' | grep '^30,' | awk -F, '{}' |sort -n >{}".format(dp, awkPrg, tempFn)
        os.system(cmdStr)
    elif pth.is_file() and dp.endswith("_upload.csv"):
        print("processing uncompressed .csv file '{}' ..".format(dp))
        awkPrg = '{ OFS=","; print $4, $14,$16; }'
        cmdStr = "cat '{}' | grep '^30,' | awk -F, '{}' |sort -n >{}".format(dp, awkPrg, tempFn)
        os.system(cmdStr)
    elif pth.is_file() and dp.endswith("_fm_rds.csv"):
        print("processing uncompressed .csv file '{}' ..".format(dp))
        awkPrg = '{ OFS=","; print $3, $13,$15; }'
        cmdStr = "cat '{}' | awk -F, '{}' |sort -n >{}".format(dp, awkPrg, tempFn)
        os.system(cmdStr)

    print("  shell finished. reading temporary .txt ..")
    dA = read(tempFn)
    if writeFiles:
        outFn = str(pthabs.parent) + "/" + str(pthabs.name) + "_overview.csv"
        print("  writing dictionary to '{}' ..".format(outFn))
        with open( outFn, "w" ) as outFile:
            nkeys_total, nkeys_with_ps, nkeys_empty_ps = printSorted(dA, outFile, numPStoPrint, printPSCounterInc)
            outFile.close()
            if renOverviewFile:
                outPth = Path(outFn)
                newFn = str(pthabs.parent) + "/" + str(pthabs.name) + "_overview_{}-{}-{}.csv".format(nkeys_total, nkeys_with_ps, nkeys_empty_ps)
                outPth.rename( newFn )
            if writeOverviewsCatalog:
                ovFn = str(pthabs.parent) + "/overviews.csv"
                ovPth = Path(ovFn)
                printHdr = not ovPth.exists()
                with open( ovFn, "a" ) as ovFile:
                    if printHdr:
                        print('"directory", "#PI", "#PS", "#rawPI"', file=ovFile)
                    print('"{}", {}, {}, {}'.format(str(pthabs.name)[0:20], nkeys_total, nkeys_with_ps, nkeys_empty_ps), file=ovFile)
                    ovFile.close()
    else:
        nkeys_total, nkeys_with_ps, nkeys_empty_ps = printSorted(dA, None, numPStoPrint, printPSCounterInc)

    print("  finished.")
    os.chdir(prevDir)
    print('15, {}, {}, {}'.format(nkeys_total, nkeys_with_ps, nkeys_empty_ps))

tmpf = Path(tempFn)
tmpf.unlink()
os.chdir(prevDir)
