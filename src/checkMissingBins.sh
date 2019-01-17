#!/bin/bash

for f in $(ls -1 $HOME/bin/) ; do
  if [ -f "$f" ]; then
    echo -e "$f\t\t."
  elif [ -f "scanner/$f" ]; then
    echo -e "$f\t\tscanner"
  else
    echo -e "$f\t\t\tMISSING"
  fi
done
