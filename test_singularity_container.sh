export examcard='/home/dylan/Documents/examcard2txt/INPUTS/examcard_012.dcm'
export outdir='/home/dylan/Documents/examcard2txt/OUTPUTS'
export project='NO_PROJECT'
export subject='NO_SUBJECT'
export session='NO_SESSION'

singularity run --cleanenv --contain \
    --home $(pwd -P) \
    --bind $(pwd -P)/INPUTS:/INPUTS \
    --bind $(pwd -P)/OUTPUTS:/OUTPUTS \
    examcard2txt_v2.simg \
    --examcard "${examcard}" \
    --outdir "${outdir}" \
    --project "${project}" \
    --subject "${subject}" \
    --session "${session}"