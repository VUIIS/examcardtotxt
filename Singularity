Bootstrap: docker
From: ubuntu:20.04

%help
	Info and usage: /opt/pipeline/README.md

%setup
  # Create an installation directory for the codebase. We can often finagle this
  # in the 'files' section and forgo the 'setup' section entirely, but it's 
  # clearer this way.
  mkdir -p "${SINGULARITY_ROOTFS}"/opt/pipeline

%environment
  export LANG=en_US.UTF-8
  export LC_ALL=C.UTF-8 
  export LANGUAGE=en_US.UTF-8

%files
  # Used to copy files into the container
  examcard2txt 		  /opt/pipeline
  README.txt        /opt/pipeline

%labels
  Maintainer r.dylan.lawless@vumc.org


%post
  
  # Install misc tools

  apt-get update 
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
    make \
    perl \
    cpanminus \
    gcc \
    build-essential \
    wget \
    unzip \
    zip \
    bc \
    curl \
    libxml-libxml-perl \
    imagemagick \
    expat \
    libexpat1-dev \
    wkhtmltopdf \
    software-properties-common
  
  apt-get -y clean
  rm -rf /var/lib/apt/lists/*

  # Create a few directories to use as bind points when we run the container
  mkdir /INPUTS
  mkdir /OUTPUTS

  # Clean up unneeded packages and cache
  apt clean && apt -y autoremove

  # Set up Perl
  cpanm XML::Parser; rm -fr root/.cpanm

%runscript
  
  # We just call our entrypoint, passing along all the command line arguments 
  # that were given at the singularity run command line.
  /opt/pipeline/examcard2txt/pipeline_entrypoint.sh "$@"