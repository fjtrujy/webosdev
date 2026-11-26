# webosdev

Containerized native development environment for LG webOS televisions, targeting
32-bit ARM (arm-webos-linux-gnueabi) from Linux ARM64 hosts. This is not a
webOS OSE SDK or a browser application environment.

## Base image

The default image uses Node.js 24 on Alpine Linux. The upstream Linux ARM64
SDK is glibc-linked; Alpine gcompat alone cannot satisfy its GCC dependencies.
A small set of real Debian Bookworm glibc runtime libraries is copied from a
separate build stage, with their copyright notices. The rest of the final
image uses Alpine packages and musl. This changes only the host environment,
not the ARMv7 webOS target sysroot.

The original Debian-based image is available at the initial commit SHA tag
`4b80f81cf33418cf79da5d55f8bcb2ae3f5ca34b`. Both MM2 renderer variants and the
standalone SDL/IPK smoke test passed locally on the Alpine image.

## Build locally

```sh
./fetch-sdk.sh
docker build --platform linux/arm64 -t webosdev:local .
docker run --rm -v "$PWD/tests:/tests:ro" webosdev:local sh /tests/smoke.sh
```

The published image is `ghcr.io/fjtrujy/webosdev:latest` after the publishing
workflow completes; commit SHA and release tag versions are also published.
The package is initially private. Grant other repositories Actions read access
in the GHCR package settings before using it as a job container.

## Usage

```sh
docker run --rm -v "$PWD:/work" -w /work webosdev:local bash
```

- `WEBOS_SDK`: relocated native cross-compiler and sysroot.
- `WEBOS_SDL`: SDL-webOS headers, libraries, and license.
- `WEBOS_CLI`: pinned LG packaging CLI executable.
- CMake, GCC, Make, pkg-config, Node.js, npm and binutils are included.

The SDK provides a CMake toolchain file at
`$WEBOS_SDK/share/buildroot/toolchainfile.cmake`. For standalone compiler
invocations specify `--sysroot="$WEBOS_SDK/arm-webos-linux-gnueabi/sysroot"`.

## CI

Use an ARM64 runner (`ubuntu-24.04-arm`) with the GHCR image. The publishing
workflow builds and smoke-tests the image before publishing. The smoke test
cross-compiles a native SDL program and packages and inspects its IPK;
it does not run on a physical television.

## Upstream components

- [webOS native-toolchain webos-d7ed7ee.6](https://github.com/webosbrew/native-toolchain/releases/tag/webos-d7ed7ee.6)
- [SDL-webOS 2.30.12-webos.5](https://github.com/webosbrew/SDL-webOS/releases/tag/release-2.30.12-webos.5)
- [LG webOS CLI 3.2.6](https://www.npmjs.com/package/@webos-tools/cli)
- [Node.js Docker image](https://github.com/nodejs/docker-node)

SDK and SDL release archives are checksum-pinned. The npm lockfile pins CLI
dependencies. Upstream components retain their respective licenses; review
their redistribution terms and source availability before public distribution.
This repository contains no original game assets or device credentials.

Linux x86-64 is not supported by the pinned SDK release. Native ARM64 hosts
are recommended; x86-64 emulation has not been validated.
