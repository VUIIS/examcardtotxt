#!/bin/bash

### Script for examcard conversion singularity container
# Dylan Lawless
# Usage: run_examcard_conversion: [--examcard] [--outdir] [--project] [--subject] [--session]


# Initialize defaults
export examcard=NO_EXAMCARD
export outdir=NO_OUTDIR
export project=NO_PROJECT
export subject=NO_SUBJECT
export session=NO_SESSION


# Parse options
while [[ $# -gt 0 ]]; do
  key="${1}"
  case $key in
    --examcard)
      export examcard="${2}"; shift; shift ;;
    --outdir)
      export outdir="${2}"; shift; shift ;;
    --project)
      export project="${2}"; shift; shift ;;
    --subject)
      export subject="${2}"; shift; shift ;;
    --session)
      export session="${2}"; shift; shift ;;
    *)
      echo Unknown input "${1}"; shift ;;
  esac
done

# copy examcard dicom to outdir
cp "${examcard}" "${outdir}"/ExamCard

# Execute perl command
/opt/pipeline/xnatwrapper/ConvertExamCard.py \
  -i "${examcard}" -o "${outdir}" -p "${project}"

wkhtmltopdf "${out_dir}"/ExamCard/*.html \
"${out_dir}"/"${xnat_project}"_"${xnat_subject}"_"${xnat_session}"_examcard.pdf
