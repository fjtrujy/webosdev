#!/bin/sh
set -eu
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"
mkdir -p app/lib
cat > main.c <<'C'
#include <SDL.h>
int main(void) {
    SDL_version version;
    SDL_GetVersion(&version);
    return version.major != 2;
}
C
arm-webos-linux-gnueabi-gcc --sysroot="$WEBOS_SDK/arm-webos-linux-gnueabi/sysroot" \
    -I"$WEBOS_SDL/include/SDL2" main.c -L"$WEBOS_SDL/lib" \
    -Wl,-rpath,'$ORIGIN/lib' -lSDL2 -o app/smoke
arm-webos-linux-gnueabi-readelf -h app/smoke | grep -E 'Machine:.*ARM'
arm-webos-linux-gnueabi-readelf -d app/smoke | grep -F '[$ORIGIN/lib]'
arm-webos-linux-gnueabi-readelf -d app/smoke | grep -F '[libSDL2-2.0.so.0]'
cp "$WEBOS_SDL/lib/libSDL2-2.0.so.0.3000.12" app/lib/libSDL2-2.0.so.0
cp "$WEBOS_SDL/share/licenses/SDL2/LICENSE.txt" app/lib/SDL2-LICENSE.txt
printf '%s\n' '{"id":"org.webosdev.smoke","version":"0.0.1","title":"SDK smoke test","main":"smoke","type":"native","vendor":"webosdev","icon":"icon.png","requiredACG":[]}' > app/appinfo.json
# A valid minimal PNG for the test package.
printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=' | base64 -d > app/icon.png
ares-package -o "$WORK" app
test -s org.webosdev.smoke_0.0.1_arm.ipk
ar -p org.webosdev.smoke_0.0.1_arm.ipk data.tar.gz | tar -tzf - > contents
grep -Fx usr/palm/applications/org.webosdev.smoke/smoke contents
grep -Fx usr/palm/applications/org.webosdev.smoke/lib/libSDL2-2.0.so.0 contents
