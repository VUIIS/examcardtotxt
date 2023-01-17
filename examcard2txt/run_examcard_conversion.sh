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
mkdir "${outdir}"/ExamCard
cp "${examcard}" "${outdir}"/ExamCard/$(basename "$examcard")

# Execute perl command
/opt/pipeline/examcard2txt/ConvertExamCard.py \
  -i "${examcard}" -o "${outdir}" -p "${project}"

/opt/pipeline/examcard2txt/convert_to_csv.py \
  -o "${outdir}"

mkdir "${outdir}"/PDF
weasyprint -q "${outdir}"/ExamCard/*.html \
"${outdir}"/PDF/"${project}"_"${subject}"_"${session}"_examcard.pdf

