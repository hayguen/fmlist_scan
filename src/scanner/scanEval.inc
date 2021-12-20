
# for inclusion (bash source) from other scanEval* scripts

export LC_ALL=C
source $HOME/.config/fmlist_scan/config

if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner" ]; then
  exit 1
fi

if [ -z "$1" ]; then
  cd "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner"
  DD=$(find . -maxdepth 1 -type d |grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" |sort |tail -n 1)
  cd "$DD"
elif [ -d "$1" ]; then
  cd "$1"
else
  cd "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner"
  if [ ! -d "$DD" ]; then
    exit 1
  fi
  cd "$1"
fi

