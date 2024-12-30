# ------------
# Build Stage: Get Dependencies
# ------------
FROM alpine:latest AS get-dependencies
LABEL stage=builder

LABEL org.opencontainers.image.description="A PROS Build Container"
LABEL org.opencontainers.image.source=https://github.com/lemlib/pros-build
LABEL org.opencontainers.image.licenses=MIT

# Install Required Packages and ARM Toolchain
RUN apk add --no-cache gcompat libc6-compat libstdc++ wget git gawk python3 pipx make unzip bash && \
    wget "https://developer.arm.com/-/media/Files/downloads/gnu/13.3.rel1/binrel/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz" -O arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz && \
    tar xf arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz && \
    rm arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz && \
    mv arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi /arm-none-eabi-toolchain && \
    rm -rf /arm-none-eabi-toolchain/share && \
    rm -rf /arm-none-eabi-toolchain/lib/gcc/arm-none-eabi/13.3.1/arm && \
    find /arm-none-eabi-toolchain/lib/gcc/arm-none-eabi/13.3.1/thumb -mindepth 1 -maxdepth 1 ! -name 'v7-a+fp' -exec rm -rf {} + && \
    find /arm-none-eabi-toolchain/arm-none-eabi/lib/thumb -mindepth 1 -maxdepth 1 ! -name 'v7-a+fp' -exec rm -rf {} + && \
    rm -f /arm-none-eabi-toolchain/bin/arm-none-eabi-gcc-13.3.1 && \
    rm -f /arm-none-eabi-toolchain/bin/arm-none-eabi-gdb && \
    rm -f /arm-none-eabi-toolchain/bin/arm-none-eabi-gdb-py && \
    rm -f /arm-none-eabi-toolchain/bin/arm-none-eabi-cpp && \
    rm -f /arm-none-eabi-toolchain/lib/gcc/arm-none-eabi/13.3.1/{*,.*} && \
    rm -rf /arm-none-eabi-toolchain/include && \
    pipx install pros-cli && \
    apk cache clean


# ------------
# Runner Stage
# ------------
FROM alpine:latest AS runner
LABEL stage=runner
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
