#!/bin/bash

export examcard_file='/home/dylan/Documents/examcard2txt/examcard_012.dcm'
export outdir='/home/dylan/Documents/examcard2txt/OUTPUTS'

/home/dylan/Documents/master-repos/examcard2txt/examcard2txt/run_examcard_conversion.sh \
  --examcard "${examcard_file}" --outdir "${outdir}"