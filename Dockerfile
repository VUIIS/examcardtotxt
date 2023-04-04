# Examcard2txt Dockerfile
FROM ubuntu:focal-20221130

# Move files
RUN mkdir -p /opt/pipeline && \
	mkdir -p /opt/pipeline/examcard2txt
COPY examcard2txt		/opt/pipeline/examcard2txt
COPY README.md 			/opt/pipeline
COPY dcm4che-2.0.25		/opt/dcm4che-2.0.25

# Prepare environment
ENV LANG=en_US.UTF-8 
ENV LC_ALL=C.UTF-8 
ENV LANGUAGE=en_US.UTF-8 
ENV PATH=/opt/dcm4che-2.0.25/bin:$PATH

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	    curl \
	    bzip2 \
	    make \
	    perl \
	    cpanminus \
	    gcc \
	    build-essential \
	    openjdk-8-jdk \
	    ant \
	    wget \
	    unzip \
	    zip \
	    python3 \
	    python3-pip \
	    python3-cffi \
	    python3-brotli \
	    libpango-1.0-0 \
	    libharfbuzz0b \
	    libpangoft2-1.0-0 \
	    bc \
	    libxml-libxml-perl \
	    imagemagick \
	    expat \
	    libexpat1-dev \
	    software-properties-common && \
	apt-get -y clean && apt -y autoremove && \
	rm -rf /var/lib/apt/lists/*

# Fix java certificate issues
RUN apt-get update && \
    apt-get install ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;

# Create a few directories to use as bind points when we run the container
RUN mkdir /INPUTS && \
	mkdir /OUTPUTS

# Set up Perl
RUN cpanm XML::Parser; rm -fr root/.cpanm

# Install pip packages
RUN   python3 -m pip --no-cache-dir install setuptools --upgrade && \
  python3 -m pip --no-cache-dir install lxml && \
  python3 -m pip --no-cache-dir install weasyprint && \
  python3 -m pip --no-cache-dir install pandas && \
  python3 -m pip --no-cache-dir install numpy

 # Run main script
 ENTRYPOINT ["/opt/pipeline/examcard2txt/run_examcard_conversion.sh"]