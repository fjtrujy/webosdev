#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CACHE="$ROOT/.cache"
mkdir -p "$CACHE"
fetch() {
    if [ ! -f "$CACHE/$2" ]; then
        curl --fail --location --retry 3 "$1/$2" -o "$CACHE/$2.part"
        mv "$CACHE/$2.part" "$CACHE/$2"
    fi
}
fetch https://github.com/webosbrew/native-toolchain/releases/download/webos-d7ed7ee.6 arm-webos-linux-gnueabi_sdk-buildroot_linux-aarch64.tar.bz2
fetch https://github.com/webosbrew/SDL-webOS/releases/download/release-2.30.12-webos.5 SDL2-2.30.12-webos.tar.gz
(cd "$CACHE" && if command -v sha256sum >/dev/null 2>&1; then sha256sum -c "$ROOT/sdk-checksums.sha256"; else shasum -a 256 -c "$ROOT/sdk-checksums.sha256"; fi)
