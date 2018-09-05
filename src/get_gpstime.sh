#!/bin/bash

cd $HOME/ram
COOR=$( ( flock -x 213 ; cat gpscoor.log 2>/dev/null ) 213>gps.lock )
if [ -z "$COOR" ]; then
  DTF="NO-GPS_SYSTIME $(date -u "+%Y-%m-%dT%T.%NZ")"
  COOR="$DTF"
fi
echo "$COOR"

