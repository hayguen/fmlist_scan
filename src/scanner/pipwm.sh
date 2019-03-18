#!/bin/bash
ID="$0 $1"
SEQ="$1"
shift

echo "called ${ID} : $@"

(
  flock --verbose -e 234

  echo "${ID} : calling pipwm $@: pgrep = $(sudo pgrep $HOME/bin/pipwm)"
  pipwm "$@" >/dev/null 2>&1

  sleep 0.8   # wait a bit more to create a small pause
  echo "${ID} : waited additional 0.8 sec"

) 234>/dev/shm/Beep.lock

echo "${ID} : finished"

