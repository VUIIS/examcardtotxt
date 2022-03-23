#!/bin/bash

export examcard_file='/home/dylan/Documents/examcard/INPUTS/1.3.46.670589.11.45051.5.0.46596.2019060512405907002-0-1-3ay0i5.dcm'
export outdir='/home/dylan/Documents/examcard/OUTPUTS/'

/home/dylan/Documents/examcard2txt/xnatwrapper/run_examcard_conversion.sh \
  --examcard "${examcard_file}" --outdir "${outdir}"