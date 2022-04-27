#!/bin/bash

SCRIPT=$(realpath -s "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
source "${SCRIPTPATH}/scanEval.inc"

zcat *_scanner.log.gz |grep Duration
