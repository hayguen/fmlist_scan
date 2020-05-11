
# number of parallel jobs with gnu parallel : use multiple cores/threads of cpu
par_jobs="3"
# define ukw/fm band in Hz
ddc_step="100000"
ukw_beg="87500000"
ukw_end="108000000"

# default record chunk duration in seconds
chunkduration="4"

# chunk duration for selected channels - containing the selchunkfreqs
selchunkduration="10"
selchunkfreqs=( )

# chunksrate = 171 * 14 = 2394 kHz, keep this value high to avoid aliasing!
chunk2mpx_dec="14"

# special for rtl-sdr.com V3 dongles, to control current for an external LNA
RTL_BIASTEE="0"          # "0" or "1"; "1" to activate power on BiasT

# common amongst different tuners is the HF gain. with R820T/2, this is LNA and Mixer.
#RTL_HF_GAIN="-g 20"   # activate this line for manual HF gain. with R820T/2, this is LNA and Mixer
RTL_HF_GAIN=""        # empty string activates the HF-AGC

# only the R820T/2 tuners support an IF gain: VGA behind LNA and Mixer
#RTL_IF_GAIN=""        # empty string activates defaults: +16.3 dB for manual gain. +26.5 dB for HF agc
RTL_IF_GAIN="ifm=0"   # this activates the AGC for the VGA - might sometimes hang on strong impulses
                      # in addition, you'll need to activate "dagc=1" to avoid oversteering
#RTL_IF_GAIN="ifm=200" # this sets ~ +20.0 dB in 10th dB. range is -4.7 to 40.8 dB

# all RTL2832U - have a digital AGC - after ADC, mixer, anti-alias-filter and down-sampling
#RTL_DAGC="dagc=0"     # switch off
RTL_DAGC="dagc=1"     # switch on - helps at oversteering

# als only for R820T/2 tuners: shift receive band 0 to 300 kHz in 100 kHz steps
#   this is in addition to to sideband swapping for every scan
USE_BCSHIFT="1"       # activate band shifting
#USE_BCSHIFT="0"       # deactivate band shifting


# end of user settings
############################################################################


# switch tuner sideband with every scan - this is only used with the R820T
if [ -z "${FMSCAN_NO}" ]; then
  SB=""
  SBOPT=""
  BCMUL="-1"   # default is LSB .. where steep low pass is at low frequency. let high pass run over right band
else
  SB=$[ ${FMSCAN_NO} % 2 ]
  SBOPT="sb=${SB}"
  # -1 for LSB with SB=0,  +1 for USB with SB=1
  BCMUL=$[ ${SB} * 2 - 1 ]
fi

# deactivate band center depending on tuner sideband
# BCMUL="1"


# initialize/clear asymetric filter.
# fill in the first/last stations frequency - relative to center/LO
# that is flat bandwidth region .. each side reduced by ~ 100 kHz
mpxsrate_chunkbw_factor="3"
center_beg=""
center_last=""
RTLC="0"
BCSHIFT="0"    # can't be use without suitable tuner

# good R820T bws:
#  290 kHz @ 600 kHz: 530 .. 670 kHz: 2 channels
#  375 kHz @ 600 kHz: 488 .. 712 kHz: 3 channels
#  420 kHz @ 600 kHz: 465 .. 735 kHz: 3 channels
#  470 kHz @ 600 kHz: 440 .. 760 kHz: 4 channels
#  600 kHz @ 600 kHz: 375 .. 825 kHz: 5 channels
#  860 kHz @ 600 kHz: 245 .. 955 kHz: 8 channels
#  950 kHz @ 500 kHz: 100 .. 900 kHz: 9 channels
# 1100 kHz @ 0
# 1300 kHz @ 0
# 1500 kHz @ 0
# 1600 kHz @ 0
# 1750 kHz @ 0


if [ "${FMLIST_FM_DEV_R820T}" = "1" ]; then
  # this section is for the R820T/2 tuner
  RTLBW="950"
  #RTLBW="600"
  #RTLBW="470"
  RTLC="500"

  if [ "${GPSSRC}" = "static" ]; then
    # spend more time on scanning in static environment
    chunkduration="6"
    RTLBW="600"
    RTLC="600"
  fi

  # band center shift
  SCANMOD=$[ ( ${FMSCAN_NO} % 8 ) / 2 ]
  BCSHIFT=$[ ${USE_BCSHIFT} * ${SCANMOD} * 100 ]
  RTLCMUL=$[ ${BCMUL} * ${RTLC} ]

  if [ -z "${RTL_HF_GAIN}" ]; then
    RTLSDR_OPT="-O verbose:T=${RTL_BIASTEE}:bw=${RTLBW}:bc=${RTLCMUL}000:agc=1:${RTL_IF_GAIN}:${RTL_DAGC}:${SBOPT}"
  else
    RTLSDR_OPT="${RTL_HF_GAIN} -O verbose:T=${RTL_BIASTEE}:bw=${RTLBW}:bc=${RTLCMUL}000:${RTL_IF_GAIN}:${RTL_DAGC}:${SBOPT}"
  fi

else
  # this section is for non-R820T/2 tuners like E4000 or FC0013 or ..

  RTLBW="1800"

  if [ "${GPSSRC}" = "static" ]; then
    # spend more time on scanning in static environment
    chunkduration="6"
    RTLBW="1200"
  fi

  if [ -z "${RTL_HF_GAIN}" ]; then
    RTLSDR_OPT="-O verbose:T=${RTL_BIASTEE}:bw=${RTLBW}:agc=1:${RTL_DAGC}"
  else
    RTLSDR_OPT="${RTL_HF_GAIN} -O verbose:T=${RTL_BIASTEE}:bw=${RTLBW}:${RTL_DAGC}"
  fi

fi

RTL_BW_OPT="-w ${RTLBW}000"

if [ ! -z "${FMLIST_FM_RTLSDR_DEV}" ]; then
  RTLSDR_OPT="${RTLSDR_OPT} -d ${FMLIST_FM_RTLSDR_DEV}"
fi

center_beg=$[  ( ${BCMUL} * ( ${RTLC} - ${BCSHIFT} ) - ${RTLBW} / 2 + 75 ) * 1000 ]
center_last=$[ ( ${BCMUL} * ( ${RTLC} - ${BCSHIFT} ) + ${RTLBW} / 2 - 75 ) * 1000 ]

