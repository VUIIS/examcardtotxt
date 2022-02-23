#!/usr/bin/env bash

# Main pipeline
echo Running $(basename "${BASH_SOURCE}")

# Execute perl command
/opt/examcard2txt/examcard2txt.pl \
	-nohtml -nodata \
	-out "${out_dir}" \
	-file "${examcard}"