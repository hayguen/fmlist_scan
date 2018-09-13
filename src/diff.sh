#!/bin/bash

if [ -z "$1" ]; then
  echo "usage: $0 [print] [<BINDIR>]"
  echo "  default BINDIR is \$HOME/bin"
  echo ""
fi

BINDIR="$HOME/bin"
if [ ! -z "$2" ]; then
  BINDIR="$2"
fi

for f in `ls -1 *.sh scanner/*.sh` ; do
  b=$( basename "$f" )

  if [ "$b" == "all.sh" ]; then
    continue
  fi
  if [ "$b" == "diff.sh" ]; then
    continue
  fi

  if [ -f "${BINDIR}/$b" ]; then
    ND=$( diff $f "${BINDIR}/$b" | wc -l )
    if [ $ND -eq 0 ]; then
      echo -e "diff $f:\t\tequal"
    else
      echo -e "diff $f:\t\tNOT equal"
      if [ "$1" == "print" ]; then
        diff "$f" "${BINDIR}/$b"
        echo ""
      fi
    fi
  else
    echo "$b not in ${BINDIR}"
  fi
done
