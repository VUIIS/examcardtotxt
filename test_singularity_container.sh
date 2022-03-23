export examcard='/home/dylan/Documents/examcard/INPUTS/test.dcm'
export outdir='/home/dylan/Documents/examcard/OUTPUTS/'
export project='NO_PROJECT'
export subject='NO_SUBJECT'
export session='NO_SESSION'

singularity run --cleanenv --contain \
    --home $(pwd -P) \
    --bind $(pwd -P)/INPUTS:/INPUTS \
    --bind $(pwd -P)/OUTPUTS:/OUTPUTS \
    examcard2txt.simg \
    --examcard "${examcard}" \
    --outdir "${outdir}" \
    --project "${project}" \
    --subject "${subject}" \
    --session "${session}"