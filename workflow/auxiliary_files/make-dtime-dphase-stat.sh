#!/bin/bash
#
# Copyright 2018 Alexander Nitz
#
# This work is licensed under a Creative Commons Attribution-ShareAlike 3.0
# United States License.
#
# https://creativecommons.org/licenses/by-sa/3.0/us/
#
# This script generates the time-phase statistic file used by the search
# pipeline. This file is described in Nitz el al., Astrophys.J. 849 (2017)
# no.2, 118.
#

pycbc_stat_dtphase \
--ifos H1 L1 \
--sample-size 10000000 \
--min-snr 4.0 \
--max-snr 30 \
--timing-error .0005 \
--snr-error 1 \
--cores 8 \
--min-detector-ratio .8 \
--detector-ratio-granularity .05 \
--seed 10 \
--bin-density 3 \
--coinc-threshold .002 \
--output-file dtime-dphase-stat.hdf \
--verbose
