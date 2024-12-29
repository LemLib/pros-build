FROM alpine:latest

LABEL org.opencontainers.image.description="A PROS Build Container"
LABEL org.opencontainers.image.source=https://github.com/lemlib/pros-build
LABEL org.opencontainers.image.licenses=MIT
# ------------
# Install Required Packages
# ------------   
# COPY packagelist /packagelist
# RUN apt-get update && apt-get install -y $(cat /packagelist) && apt-get clean
# RUN rm /packagelist # Cleanup Image

# See: https://github.com/Jerrylum/pros-build/blob/main/Dockerfile
RUN apk add --no-cache gcompat libc6-compat libstdc++ wget git gawk python3 pipx make unzip

# ------------
# Set Timezone and set frontend to noninteractive
# ------------
# ENV DEBIAN_FRONTEND=noninteractive
# RUN echo "tzdata tzdata/Areas select America" | debconf-set-selections \
#     && echo "tzdata tzdata/Zones/America select Los_Angeles" | debconf-set-selections

# ------------
# Install ARM Toolchain
# ------------
RUN wget "https://developer.arm.com/-/media/Files/downloads/gnu/13.3.rel1/binrel/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz" -O arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz
RUN tar xf arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz
RUN rm arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz # Cleanup Image
RUN mv "/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi" "/arm-none-eabi-toolchain"
ENV PATH="/arm-none-eabi-toolchain/bin:${PATH}"

# ------------
# Install PROS CLI
# ------------
RUN pipx install pros-cli
ENV PATH="/root/.local/bin:$PATH"

# ------------
# Cleanup 
# ------------

# Cleanup APT
#RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Cleanup APK
RUN apk cache clean
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

ENV PROS_PROJECT=${PROS_PROJECT}
ENV REPOSITORY=${REPOSITORY}
ENV LIBRARY_PATH=${LIBRARY_PATH}

RUN env

COPY build-tools/build.sh $HOME/build.sh
RUN chmod +x $HOME/build.sh
RUN cat $HOME/build.sh

COPY LICENSE ./LICENSE

ENTRYPOINT ["$HOME/build.sh"]
