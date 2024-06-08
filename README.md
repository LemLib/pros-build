# PROS Build Action

[![Build-Image action](https://github.com/LemLib/pros-build/actions/workflows/build-image.yml/badge.svg)](https://github.com/LemLib/pros-build/actions/workflows/build-image.yml)
[![Test action](https://github.com/LemLib/pros-build/actions/workflows/test.yml/badge.svg)](https://github.com/LemLib/pros-build/actions/workflows/test.yml)

This action creates an environment capable of building PROS projects and templates, and builds them using [build.sh](/build-tools/build.sh)

Instructions on creating a custom build script, adding additional packages, and using this image as a base are located at the end of this readme.

## Usage:

### Inputs

- `multithreading`
  - Wether to use multithreading when building the project
  - Default: `true`
  - Required: `false`
- `no_commit_hash`
  - Wether to include a shortened commit hash at the end of the artifact name
  - Example: `LemLib@0.5.1+5881ac`
  - Default: `true`
  - Required: `false`
- `copy_readme_and_license_to_include`
  - Whether to make a VERSION file, copy the README(.md), and copy the LICENSE(.md) files to the `/include/(library name)` folder.
  - required: `false`
  - default: `false`
- `lib_folder_name`
  - The name of the library's folder name under the include directory.
  - required: `if copy_readme_and_license_to_include is set`
- `write_job_summary`
  - Whether to output to GitHub's Job Summary (See the bottom of this README)
  - required: `false`
  - default: `true`

### Outputs
> [!NOTE]  
> While this action has the `name` output for the artifact name, it does not upload the artifact itself. The `name` output is meant to be passed into `actions/upload-artifact`.

- `name`
  - The recommended name for an artifact.

### Example Workflow

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
        uses: actions/checkout@v4

      - name: Run LemLib/pros-build
        id: test
        uses: LemLib/pros-build

      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          name: ${{ steps.test.outputs.name }}
          path: ${{ github.workspace }}/template/*
```

## Using the Container in your own build script

If you wish to use your own build script using this container as a base, you can do so with the following:

It by default includes the packages built into the Ubuntu docker image, and contains the additional packages below:

```
wget (Used to download the toolchain)
git (Used to get the HEAD SHA hash)
gawk (Used to get lines from the user project's Makefile)
python3-minimal (Minimal installation of Python used for pros-cli)
python3-pip (Used to install pros-cli in the Dockerfile)
unzip (Unzips the template so that it can be uploaded to Github Actions)
pros-cli (through python)
```

### Editing the Dockerfile
```Dockerfile
FROM ghcr.io/LemLib/pros-build:stable

# Remove the included build script.
RUN rm -rf /build.sh

## Do what you wish here, such as copying your own build script in, add dependencies, etc

# Override ENTRYPOINT with your own. This isn't strictly necessary if you name your build script build.sh and put it in the root of the container (Such as /build.sh)
ENTRYPOINT []
```


# Example Job Summary Output
# ✅ Build Completed
Build completed in 25 seconds
Total Build Script Runtime: 27 seconds
## 📝 Library Name: LemLib @ 0.5.1
### 🔐 SHA: 4f12f2

### 📁 Artifact Name: LemLib@0.5.1+4f12f2
***
#### 📄 Output from Make
<details><summary>Click to expand</summary> 
```
        Creating bin/LemLib.a  [DONE]
Creating cold package with libpros,libc,libm,LemLib [OK]
Stripping cold package  [DONE]
Section sizes:
   text	   data	    bss	  total	    hex	filename
1013.69KB  4.89KB  47.15MB  48.14MB 30234f7 bin/cold.package.elf
Adding timestamp [OK]
Linking hot project with ./bin/cold.package.elf and libpros,libc,libm,LemLib [OK]
Section sizes:
   text	   data	    bss	  total	    hex	filename
 3.97KB  12.00B  46.02MB  46.02MB 2e04a17 bin/hot.package.elf
Creating cold package binary for VEX EDR V5 [DONE]
Creating bin/hot.package.bin for VEX EDR V5 [DONE]
```
</details>

### 📦 Artifact url: https://github.com/LemLib/pros-build/actions/runs/9426610142/artifacts/1581443703