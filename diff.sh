#!/bin/bash

if [ -z "$1" ]; then
  echo "usage: $0 [print]"
  echo ""
fi

for f in `ls -1 *.sh scanner/*.sh` ; do
  b=$( basename "$f" )

  if [ "$b" == "all.sh" ]; then
    continue
  fi
  if [ "$b" == "diff.sh" ]; then
    continue
  fi

  if [ -f "$HOME/bin/$b" ]; then
    ND=$( diff $f $HOME/bin/$b | wc -l )
    if [ $ND -eq 0 ]; then
      echo -e "diff $f:\t\tequal"
    else
      echo -e "diff $f:\t\tNOT equal"
      if [ "$1" == "print" ]; then
        diff "$f" "$HOME/bin/$b"
        echo ""
      fi
    fi
  else
    echo "$b not in $HOME/bin"
  fi
done
