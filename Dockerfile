FROM alpine:latest as get-dependencies 

LABEL org.opencontainers.image.description="A PROS Build Container"
LABEL org.opencontainers.image.source=https://github.com/lemlib/pros-build
LABEL org.opencontainers.image.licenses=MIT

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
RUN rm arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz

# RUN mkdir -p /arm-none-eabi-toolchain/arm-none-eabi/include
# RUN mkdir -p /arm-none-eabi-toolchain/bin
# RUN mkdir -p /arm-none-eabi-toolchain/libexec/
# RUN mkdir -p /arm-none-eabi-toolchain/lib
# #include dir
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/arm-none-eabi/include/* /arm-none-eabi-toolchain/arm-none-eabi/include/
# #bin files
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-c++filt /arm-none-eabi-toolchain/bin/
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-gcc /arm-none-eabi-toolchain/bin/
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-elfedit /arm-none-eabi-toolchain/bin/
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-gcc-ar /arm-none-eabi-toolchain/bin/
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-gcov /arm-none-eabi-toolchain/bin/
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-gcov-dump /arm-none-eabi-toolchain/bin/
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-gcov-tool /arm-none-eabi-toolchain/bin/
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-ld /arm-none-eabi-toolchain/bin/
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-objcopy /arm-none-eabi-toolchain/bin/
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-strip /arm-none-eabi-toolchain/bin/

# # TODO: These will be converted to aliases, I don't know how they need ot be aliased
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-g++ /arm-none-eabi-toolchain/bin/
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-nm /arm-none-eabi-toolchain/bin/
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-ranlib /arm-none-eabi-toolchain/bin/

# # TODO: Not sure if this is an alias or not
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-as /arm-none-eabi-toolchain/bin/
# # libexec
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/libexec/* /arm-none-eabi-toolchain/libexec/
# RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/lib/* /arm-none-eabi-toolchain/lib/

# Deleting the extracted toolchain
#RUN rm -rf /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi
RUN mv /arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi /arm-none-eabi-toolchain

RUN rm -rf /arm-none-eabi-toolchain/share
RUN rm -rf /arm-none-eabi-toolchain/lib/gcc/arm-none-eabi/13.3.1/arm
RUN find /arm-none-eabi-toolchain/lib/gcc/arm-none-eabi/13.3.1/thumb -mindepth 1 -maxdepth 1 ! -name 'v7-a+fp' -exec rm -rf {} +
# RUN rm /arm-none-eabi-toolchain/lib/gcc/arm-none-eabi/13.3.1/*
# RUN mv "/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi" "/arm-none-eabi-toolchain"


FROM alpine:latest as runner
COPY --from=get-dependencies /arm-none-eabi-toolchain  /arm-none-eabi-toolchain
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

COPY build-tools/build.sh /build.sh
RUN chmod +x /build.sh
RUN cat /build.sh

COPY LICENSE ./LICENSE

ENTRYPOINT ["/build.sh"]
