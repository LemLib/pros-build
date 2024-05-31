#FROM ghcr.io/abucky0/pros-build-container:main
FROM ubuntu:20.04
#FROM python:3.8

LABEL version="1.0" \
      description="This is a base image that builds an environment capable of building PROS projects." \
      maintainer="@ABUCKY0 (And LemLib Contributors)"

# ------------
# Install Required Packages
# ------------   
COPY packagelist /packagelist
RUN apt-get update && apt-get install -y $(cat /packagelist) && apt-get clean
RUN rm /packagelist # Cleanup Image

# ------------
# Set Timezone and set frontend to noninteractive
# ------------
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "tzdata tzdata/Areas select America" | debconf-set-selections \
    && echo "tzdata tzdata/Zones/America select Los_Angeles" | debconf-set-selections

# ------------
# Install ARM Toolchain
# ------------
RUN wget "https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2" -O gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2
RUN tar -xjvf gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2
RUN rm gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2 # Cleanup Image

ENV PATH="/gcc-arm-none-eabi-10.3-2021.10/bin:${PATH}"

# ------------
# Install PROS CLI
# ------------
RUN python3 -m pip install pros-cli

# ------------
# Verify Installation
# ------------
RUN python3 --version
RUN pros --version
RUN arm-none-eabi-g++ --version
RUN arm-none-eabi-gcc --version

RUN jq --version
RUN git --version
RUN make --version
RUN unzip 
RUN awk --version



# ------------
# SETUP BUILD
# ------------

ENV PROS_PROJECT ${PROS_PROJECT}
ENV REPOSITORY ${REPOSITORY}
ENV LIBRARY_PATH ${LIBRARY_PATH}

RUN env

COPY build-tools/build.sh . 
RUN chmod +x ./build.sh

COPY LICENSE .

ENTRYPOINT ["/build.sh"]