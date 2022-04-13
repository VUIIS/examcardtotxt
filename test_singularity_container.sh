export examcard='/home/dylan/Documents/examcard/INPUTS/1.3.46.670589.11.17240.5.0.10960.2016101010364405000-0-1-15p6sf2.dcm'
export outdir='/home/dylan/Documents/examcard/OUTPUTS'
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