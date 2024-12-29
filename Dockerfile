FROM ubuntu:20.04

LABEL org.opencontainers.image.description="A PROS Build Container"
LABEL org.opencontainers.image.source=https://github.com/lemlib/pros-build
LABEL org.opencontainers.image.licenses=MIT
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
RUN wget "https://developer.arm.com/-/media/Files/downloads/gnu/13.3.rel1/binrel/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz" -O arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz
RUN tar xf arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz
RUN rm arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz # Cleanup Image
RUN mv "/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi" "/arm-none-eabi-toolchain"
ENV PATH="arm-none-eabi-toolchain/bin:${PATH}"

# ------------
# Install PROS CLI
# ------------
RUN python3 -m pip install pros-cli

# ------------
# Cleanup 
# ------------

# Cleanup APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ------------
# Verify Installation
# ------------
RUN python3 --version
RUN pros --version
RUN arm-none-eabi-g++ --version
RUN arm-none-eabi-gcc --version

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
