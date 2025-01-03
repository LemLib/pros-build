# ------------
# Build Stage: Get Dependencies
# ------------
FROM alpine:latest AS get-dependencies
LABEL stage=builder

LABEL org.opencontainers.image.description="A PROS Build Container"
LABEL org.opencontainers.image.source=https://github.com/lemlib/pros-build
LABEL org.opencontainers.image.licenses=MIT

# Install Required Packages and ARM Toolchain
RUN apk add --no-cache bash
RUN mkdir "/arm-none-eabi-toolchain" && wget -O- "https://developer.arm.com/-/media/Files/downloads/gnu/13.3.rel1/binrel/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz" \
    | tar Jxf - -C "/arm-none-eabi-toolchain" --strip-components=1 
RUN <<-"EOF" bash
    set -e
    
    # Install apk packages
    apk add --no-cache gcompat libc6-compat libstdc++ wget git gawk python3 pipx make unzip
    
    toolchain="/arm-none-eabi-toolchain"
    long_toolchain="arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi"
    mkdir -p "$toolchain"
    


    rm -rf "$toolchain"/{share,include}
    rm -rf "$toolchain"/lib/gcc/arm-none-eabi/13.3.1/arm
    rm -f "$toolchain"/bin/arm-none-eabi-{gdb,gdb-py,cpp}
    rm -rf "$toolchain"/bin/arm-none-eabi-gcc-13.3.1
    
    find "$toolchain"/arm-none-eabi/lib/thumb                              -mindepth 1 -maxdepth 1 ! -name 'v7-a+fp' -exec rm -rf {} +
    find "$toolchain"/lib/gcc/arm-none-eabi/13.3.1/thumb                   -mindepth 1 -maxdepth 1 ! -name 'v7-a+fp' -exec rm -rf {} +
    find "$toolchain"/arm-none-eabi/include/c++/13.3.1/arm-none-eabi/thumb -mindepth 1 -maxdepth 1 ! -name 'v7-a*' -exec rm -rf {} + 

    # Install pros cli (Used for creating template)
    pipx install pros-cli
    apk cache clean # Cleanup image
EOF
# ------------
# Runner Stage
# ------------
FROM alpine:latest AS runner
LABEL stage=runner
LABEL org.opencontainers.image.description="A PROS Build Container"
LABEL org.opencontainers.image.source=https://github.com/lemlib/pros-build
LABEL org.opencontainers.image.licenses=MIT
# Copy dependencies from get-dependencies stage
COPY --from=get-dependencies /arm-none-eabi-toolchain /arm-none-eabi-toolchain
RUN apk add --no-cache gcompat libc6-compat libstdc++ git gawk python3 pipx make unzip bash && pipx install pros-cli && apk cache clean

# Set Environment Variables
ENV PATH="/arm-none-eabi-toolchain/bin:/root/.local/bin:${PATH}"


# Setup Build
ENV PROS_PROJECT=${PROS_PROJECT}
ENV REPOSITORY=${REPOSITORY}
ENV LIBRARY_PATH=${LIBRARY_PATH}

COPY build-tools/build.sh /build.sh
RUN chmod +x /build.sh
COPY LICENSE ./LICENSE

ENTRYPOINT ["/build.sh"]
