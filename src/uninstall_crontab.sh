
if [ -z "${FMLIST_SCAN_USER}" ]; then
  export FMLIST_SCAN_USER="pi"
fi

# remove crontab entries
# see http://theunixtips.com/bash-automate-cron-job-maintenance/
(
  crontab -l -u ${FMLIST_SCAN_USER} | grep -v startBgScanLoop.sh | grep -v checkBgScanLoop.sh | grep -v uploadScanResults.sh | grep -v "# min hour dom mon dow"  2>/dev/null
) | crontab -u ${FMLIST_SCAN_USER} -

