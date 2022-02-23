Bootstrap: docker
From: ubuntu:20.04

%help
	Info and usage: /opt/pipeline/README.md

%setup
  # Create an installation directory for the codebase. We can often finagle this
  # in the 'files' section and forgo the 'setup' section entirely, but it's 
  # clearer this way.
  mkdir -p "${SINGULARITY_ROOTFS}"/opt/pipeline


%files
  # Used to copy files into the container
  examcard2txt 		  /opt

%labels
  Maintainer r.dylan.lawless@vumc.org

%post
  
  # Install misc tools

  apt-get update
  apt-get install -y --no-install-recommends \
    perl \
    build-essential \
    wget \
    unzip \
    zip \
    bc \
    curl \
    libxml-libxml-perl
    software-properties-common
  
  apt-get -y clean
  rm -rf /var/lib/apt/lists/*

  # Create a few directories to use as bind points when we run the container
  mkdir /INPUTS
  mkdir /OUTPUTS

  # Clean up unneeded packages and cache
  apt clean && apt -y autoremove

%environment



%runscript
  
  # We just call our entrypoint, passing along all the command line arguments 
  # that were given at the singularity run command line.
  opt/examcard2txt/examcard2txt.pl "$@"