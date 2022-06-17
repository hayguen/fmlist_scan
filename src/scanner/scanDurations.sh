#!/bin/bash

# one can pass a relative or absolute directory as option
SCRIPT=$(realpath -s "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
source "${SCRIPTPATH}/scanEval.inc"

zcat *_scanner.log.gz |grep Duration
