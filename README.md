# PROS Build Action

[![Test action](https://github.com/LemLib/pros-build/actions/workflows/test.yml/badge.svg)](https://github.com/LemLib/pros-build/actions/workflows/test.yml)

This action creates an environment capable of building PROS projects. 

It by default includes the packages built into the Ubuntu docker image, and contains the additional packages below:

```
jq
wget
git
gawk
python3-minimal
python3-pip
unzip
pros-cli (through python)
```

Instructions on creating a custom build script, adding additional packages, and using this image as a base are located at the end of this readme.

## Usage:

```yml

name: PROS Build Example

on:
    push:
      branches: "**"
    pull_request:
      branches: "**"
  
    workflow_dispatch:
  
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Run LemLib/pros-build
        id: test
        uses: LemLib/pros-build

      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          name:  ${{ steps.test.outputs.name }}
          path:  ${{ github.workspace }}/template/*
```


## Using the Container in your own build script

If you wish to use your own build script using this container as a base, you can do so with the following:


```Dockerfile
FROM ghcr.io/LemLib/pros-build:main

# Remove the included build script.
RUN rm -rf /build.sh 

## Do what you wish here, such as copying your own build script in, add dependencies, etc

# Override ENTRYPOINT with your own. This isn't strictly necessary if you name your build script build.sh and put it in the root of the container (Such as /build.sh)
ENTRYPOINT []
```