FROM node:24-bookworm AS base
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake pkg-config file git curl ca-certificates bzip2 xz-utils perl \
    && rm -rf /var/lib/apt/lists/*

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

FROM base
LABEL org.opencontainers.image.source="https://github.com/fjtrujy/webosdev" \
      org.opencontainers.image.description="Native ARMv7 webOS TV SDK and SDL2 IPK development environment (Linux ARM64 host)"
COPY --from=sdk /opt/webos /opt/webos
ENV WEBOS_SDK=/opt/webos/arm-webos-linux-gnueabi_sdk-buildroot \
    WEBOS_SDL=/opt/webos/sdl \
    WEBOS_CLI=/opt/webos/cli/node_modules/.bin/ares-package \
    PATH=/opt/webos/arm-webos-linux-gnueabi_sdk-buildroot/bin:/opt/webos/cli/node_modules/.bin:$PATH
RUN arm-webos-linux-gnueabi-gcc --version \
    && ares-package --version \
    && cmake --version
WORKDIR /work
CMD ["/bin/bash"]
