# PROS Build Action

[![Test action](https://github.com/LemLib/pros-build/actions/workflows/test.yml/badge.svg)](https://github.com/LemLib/pros-build/actions/workflows/test.yml)

## Usage

Here are the basics `steps` you'd need to build a pros project:

```yml
steps:
  - uses: actions/checkout@v4
  - uses: Lemlib/pros-build@v1
```

If your pros project contains a library, this action can automatically build it as a template, and then upload it as an artifact.

```yml
steps:
  - uses: actions/checkout@v4
  - uses: Lemlib/pros-build@v1
    with:
      library-path: lemlib # make sure to substitute this with the correct path
```
