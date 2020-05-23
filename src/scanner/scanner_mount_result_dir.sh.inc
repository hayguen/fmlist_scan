
# check / mount
MNTC=$( mount | grep -c "${FMLIST_SCAN_RESULT_DIR}" )
if [ $MNTC -eq 0 ] && [ ${FMLIST_SCAN_MOUNT} -eq 1 ]; then
  mount "${FMLIST_SCAN_RESULT_DIR}"
  MNTC=$( mount | grep -c "${FMLIST_SCAN_RESULT_DIR}" )
  if [ $MNTC -eq 0 ]; then
    echo "Error: Device (USB memory stick) is not available on ${FMLIST_SCAN_RESULT_DIR} !"
    exit 10
  fi
  sudo chown ${FMLIST_SCAN_USER}:${FMLIST_SCAN_USER} "${FMLIST_SCAN_RESULT_DIR}"
fi

if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner" ]; then
  mkdir -p "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner"
fi

if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner" ]; then
  echo "Error: cannot create directory: ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner !"
  wall "Error: cannot create directory: ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner !"
  exit 1
fi

# do NOT check for space in all scripts which would include upload
#if [ ${FMLIST_SCAN_MOUNT} -eq 1 ]; then
#  FM=$( df -h -m ${FMLIST_SCAN_RESULT_DEV} | tail -n 1 | awk '{ print $4; }' )
#  if [ $FM -le 5 ]; then
#    echo "Error: not enough space on ${FMLIST_SCAN_RESULT_DEV} !"
#    wall "Error: not enough space on ${FMLIST_SCAN_RESULT_DEV} !"
#    exit 1
#  fi
#fi

