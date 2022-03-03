#!/usr/bin/env bash
#
# Test the built singularity container.

export examcard="/home/dylan/Documents/examcard/INPUTS/IRIS+iZOOM_20160805.ExamCard"
export xnat_project="TEST_PROJ"
export xnat_session="TEST_SESS"
export xnat_subject="TEST_SUBJ"
export out_dir="/home/dylan/Documents/examcard/OUTPUTS"


singularity run --cleanenv --contain \
    --home $(pwd -P) \
    --bind $(pwd -P)/INPUTS:/INPUTS \
    --bind $(pwd -P)/OUTPUTS:/OUTPUTS \
    examcard2txt_v1.0.0.simg \
    --examcard "${examcard}" \
    --out_dir "${out_dir}" \
    --xnat_project "${xnat_project}" \
    --xnat_subject "${xnat_subject}" \
    --xnat_session "${xnat_session}"