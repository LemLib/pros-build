FROM ghcr.io/abucky0/pros-build-container:main


# set GITHUB environment variables from host
# PROS_PROJECT: ${{ github.workspace }}
# REPOSITORY: ${{ inputs.repository }}
# LIBRARY_PATH: ${{ inputs.library-path }}

ENV PROS_PROJECT ${PROS_PROJECT}
ENV REPOSITORY ${REPOSITORY}
ENV LIBRARY_PATH ${LIBRARY_PATH}

RUN echo env

COPY build.sh . 
RUN chmod +x ./build.sh
RUN ls -a
ENTRYPOINT ["/build.sh"]