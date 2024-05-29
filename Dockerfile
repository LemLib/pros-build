FROM ghcr.io/abucky0/pros-build-container:main


# set GITHUB environment variables from host
# PROS_PROJECT: ${{ github.workspace }}
# REPOSITORY: ${{ inputs.repository }}
# LIBRARY_PATH: ${{ inputs.library-path }}

ENV PROS_PROJECT ${PROS_PROJECT}
ENV REPOSITORY ${REPOSITORY}
ENV LIBRARY_PATH ${LIBRARY_PATH}

RUN env

COPY build-tools/build.sh . 
RUN chmod +x ./build.sh


ENTRYPOINT ["/build.sh"]