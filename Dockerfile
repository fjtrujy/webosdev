FROM node:24-alpine AS base
RUN apk add --no-cache build-base cmake pkgconf file git curl ca-certificates bzip2 xz perl bash coreutils findutils grep sed tar gcompat

FROM base AS sdk
COPY sdk-checksums.sha256 /tmp/downloads/
COPY .cache/arm-webos-linux-gnueabi_sdk-buildroot_linux-aarch64.tar.bz2 .cache/SDL2-2.30.12-webos.tar.gz /tmp/downloads/
RUN cd /tmp/downloads && sha256sum -c sdk-checksums.sha256 \
    && mkdir -p /opt/webos/sdl \
    && tar -xjf arm-webos-linux-gnueabi_sdk-buildroot_linux-aarch64.tar.bz2 -C /opt/webos \
    && tar -xzf SDL2-2.30.12-webos.tar.gz -C /opt/webos/sdl \
    && cd /opt/webos/arm-webos-linux-gnueabi_sdk-buildroot && ./relocate-sdk.sh
COPY cli/package.json cli/package-lock.json /opt/webos/cli/
RUN cd /opt/webos/cli && npm ci --no-audit --no-fund && npm cache clean --force

FROM node:24-bookworm AS glibc
# The upstream Linux ARM64 SDK is linked against glibc, not musl.
RUN set -eu; mkdir -p /glibc-runtime /glibc-licenses; \
    for name in ld-linux-aarch64.so.1 libc.so.6 libm.so.6 libpthread.so.0 libdl.so.2 librt.so.1 libresolv.so.2 libutil.so.1 libnss_files.so.2 libnss_dns.so.2 libgcc_s.so.1 libstdc++.so.6 libexpat.so.1 libgmp.so.10 libisl.so.23 libmpc.so.3 libmpfr.so.6 libpkgconf.so.3 libreadline.so.8 libxml2.so.2; do \
        f=/lib/aarch64-linux-gnu/$name; test -e "$f"; cp -L "$f" /glibc-runtime/; \
        ldd "$f" | awk '$2 == "=>" && $3 ~ /^\// {print $3}' | while read -r dep; do cp -L "$dep" /glibc-runtime/; done; \
    done; \
    for f in /usr/share/doc/*/copyright; do cp -L "$f" "/glibc-licenses/$(basename "$(dirname "$f")").copyright"; done

FROM base
LABEL org.opencontainers.image.source="https://github.com/fjtrujy/webosdev" \
      org.opencontainers.image.description="Native ARMv7 webOS TV SDK and SDL2 IPK development environment (Linux ARM64 host)"
COPY --from=sdk /opt/webos /opt/webos
ENV WEBOS_SDK=/opt/webos/arm-webos-linux-gnueabi_sdk-buildroot \
    WEBOS_SDL=/opt/webos/sdl \
    WEBOS_CLI=/opt/webos/cli/node_modules/.bin/ares-package \
    PATH=/opt/webos/arm-webos-linux-gnueabi_sdk-buildroot/bin:/opt/webos/cli/node_modules/.bin:$PATH
RUN apk del gcompat
COPY --from=glibc /glibc-runtime/ /lib/aarch64-linux-gnu/
COPY --from=glibc /glibc-licenses/ /usr/share/licenses/glibc-runtime/
RUN ln -s aarch64-linux-gnu/ld-linux-aarch64.so.1 /lib/ld-linux-aarch64.so.1
RUN arm-webos-linux-gnueabi-gcc --version \
    && ares-package --version \
    && cmake --version
WORKDIR /work
CMD ["/bin/bash"]
