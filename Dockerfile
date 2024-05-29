FROM ghcr.io/abucky0/pros-build-container:main

COPY build.sh . 
RUN chmod +x ./build.sh
ENTRYPOINT ["./build.sh"]