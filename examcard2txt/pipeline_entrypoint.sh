#!/usr/bin/env bash
#
# Primary entrypoint for our pipeline. This just parses the command line 
# arguments, exporting them in environment variables for easy access
# by other shell scripts later. Then it calls the rest of the pipeline.
#
# Example usage:
# 
# pipeline_entrypoint.sh 

echo Running $(basename "${BASH_SOURCE}")

# Initialize defaults
export xnat_subject="TEST_SUBJ"
export xnat_subject="TEST_PROJ"
export xnat_subject="TEST_SESS"
export out_dir=/OUTPUTS

# Parse input options
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        
        --examcard)
            export examcard="$2"; shift; shift ;;

        --out_dir)
            export out_dir="$2"; shift; shift ;;

        --xnat_project)
            export xnat_project="$2"; shift; shift ;;

        --xnat_subject)
            export xnat_subject="$2"; shift; shift ;;

        --xnat_session)
            export xnat_session="$2"; shift; shift ;;

        *)
            echo "Input ${1} not recognized. Exiting program."
            exit
            shift ;;

    esac
done

# Execute perl command
/opt/pipeline/examcard2txt/examcard2txt.pl \
	-nodata \
	-out "${out_dir}" \
	"${examcard}"

wkhtmltopdf "${out_dir}"/*.html \
"${out_dir}"/"${xnat_project}"_"${xnat_subject}"_"${xnat_session}"_examcard.pdf