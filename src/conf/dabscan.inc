
# special for rtl-sdr.com V3 dongles, to control current for an external LNA
RTL_BIASTEE="0"          # "0" or "1"; "1" to activate power on BiasT

# common amongst different tuners is the HF gain. with R820T/2, this is LNA and Mixer.
#RTL_HF_GAIN="gain=200"  # activate this line for manual HF gain. with R820T/2, this is LNA and Mixer
RTL_HF_GAIN=""          # empty string activates the AGC

# only the R820T/2 tuners support an IF gain: VGA behind LNA and Mixer
#RTL_IF_GAIN=""        # empty string activates defaults: +16.3 dB for manual gain. +26.5 dB for HF agc
RTL_IF_GAIN="ifm=0"   # this activates the AGC for the VGA - might sometimes hang on strong impulses.
                      # in addition, you will need to activate "dagc=1" to avoid oversteering
#RTL_IF_GAIN="ifm=200" # this sets ~ +20.0 dB in 10th dB. range is -4.7 to 40.8 dB

# all RTL2832U - have a digital AGC - after ADC, mixer, anti-alias-filter and down-sampling
#RTL_DAGC="dagc=0"     # switch off
RTL_DAGC="dagc=1"     # switch on - helps at oversteering


# end of user settings
############################################################################



# file with channels to scan
chanlist="dab_chanlist.txt"

# verifiable TII (statistics without '-x' option) requires much time: that is why to increase -A from 2000 to 12000
#   with option '-x', activation enhanced tii algorithm with quality values, reduced -A to 6000 ms
#   options -t,  -a and -r specify how tii statistics should work ..

if [ -z "${DABSCAN_NO}" ]; then
  SBOPT=""
else
  SB=$[ ${DABSCAN_NO} % 2 ]
  SBOPT="sb=${SB}"
fi

if [ -z "${RTL_HF_GAIN}" ]; then
  DABGAIN="-Q"
  RTLGAIN="agc=1"
else
  DABGAIN="-G -1"    # use gain through -O option
  RTLGAIN="agc=0:${RTL_HF_GAIN}"
fi


# softdeadtime=2:softscantime=20:softagc=0
RTLOPT="-O verbose:T=${RTL_BIASTEE}:${RTLGAIN}:${RTL_IF_GAIN}:${RTL_DAGC}:bw=1600:${SBOPT}"

DABOPT="${DABGAIN} -E 3 -W 5000 -A 6000 -c -t 5 -a 0.8 -r 5 -x ${RTLOPT}"
DABPRESCANOPT="${RTLOPT}"
DABLISTENOPT="${DABGAIN} -t 40 -a 0.95 -r 40 -x ${RTLOPT}"

if [ "${GPSSRC}" = "static" ] && [ "${FMLIST_ALWAYS_FAST_MODE}" != "1" ]; then
  # spend more time on scanning in static environment
  DABOPT="${DABGAIN} -E 3 -W 8000 -A 12000 -c -t 10 -a 0.9 -r 10 -x ${RTLOPT}"
fi


# select rtlsdr device with option '-s <serial>'.
#   program 'rtl_test' will list all devices with their serial numbers 'SN'.
#   in case your serial numbers are not unique, you can modify these with 'rtl_eeprom'.
#   reuse devicename from config: ${FMLIST_DAB_RTLSDR_DEV}

if [ ! -z "${FMLIST_DAB_RTLSDR_DEV}" ]; then
  DABOPT="${DABOPT} -s ${FMLIST_DAB_RTLSDR_DEV}"
  DABPRESCANOPT="${DABPRESCANOPT} -d ${FMLIST_DAB_RTLSDR_DEV}"
  DABLISTENOPT="${DABLISTENOPT} -s ${FMLIST_DAB_RTLSDR_DEV}"
fi

