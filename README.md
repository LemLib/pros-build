# PROS Build Action

[![Build-Image action](https://github.com/LemLib/pros-build/actions/workflows/build-image.yml/badge.svg)](https://github.com/LemLib/pros-build/actions/workflows/build-image.yml)
[![Test action](https://github.com/LemLib/pros-build/actions/workflows/test.yml/badge.svg)](https://github.com/LemLib/pros-build/actions/workflows/test.yml)

This action creates an environment capable of building PROS projects and templates and builds them using [build.sh](/build-tools/build.sh)

Instructions on creating a custom build script, adding additional packages, and using this image as a base are located at the end of this readme.  

> [!NOTE]
> Also major thanks to [@JerryLum](https://github.com/jerrylum) for his gracious help and competition in building v4.0.0 to be as fast as it is now!
## Usage:

### Inputs

- `multithreading`
  - Whether to use multithreading when building the project
  - Default: `true`
  - Required: `false`
- `no_commit_hash`
  - Whether to include a shortened commit hash at the end of the artifact name
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
        uses: LemLib/pros-build@v4.0.0

      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          name: ${{ steps.test.outputs.name }}
          path: ${{ github.workspace }}/template/*
```

## Using the Container in your own build script

If you wish to use your own build script using this container as a base, you can do so with the following:

> [!WARNING]
> The container now (v4.* and up) uses Alpine Linux and adds the necessary packages to build a PROS Project. The currently added package is listed below, but your mileage on using anything other than basic make commands in a pros project may vary wildly depending on how you create it.   
> We also trimmed the toolchain to be much smaller, so if you've modified your Makefile to use other features you may have to fork this repository and change what is removed from the toolchain.

Installed Packages: `gcompat, libc6-compat, libstdc++, git, gawk, python3, pipx, make, unzip, bash`

### Editing the Dockerfile

```Dockerfile
FROM ghcr.io/LemLib/pros-build:v4.0.0

# Remove the included build script.
RUN rm -rf /build.sh

## Do what you wish here, such as copying your own build script in, add dependencies, etc

# Override ENTRYPOINT with your own. This isn't strictly necessary if you name your build script build.sh and put it in the root of the container (Such as /build.sh)
ENTRYPOINT []
```


# Example Job Summary Output

![image](https://github.com/user-attachments/assets/a63ddfc0-5f14-44c0-8e1b-8902f1d99e55)

