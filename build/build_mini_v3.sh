#!/usr/bin/env bash
# Build ESP32 Marauder (ZetaScrub spin) for Marauder Mini v3 (ESP32-C5).
# Recipe mirrored from .github/workflows/build_parallel.yml (C5 sibling rows).
set -euo pipefail

# Require the exact Mini v3 hardware setup; the original Mini setup bootloops on this device.
if [[ ! -f "$(dirname "$0")/../User_Setup_marauder_mini_v3.h" ]]; then
  echo "Mini v3 build stopped: exact Mini v3 display/pin setup is unavailable." >&2
  echo "The original Mini setup bootloops on ESP32-C5; do not flash that build." >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
LIBS="$BUILD/libraries"
OUT="$BUILD/out"
SKETCH="$ROOT/esp32_marauder/esp32_marauder.ino"
FQBN="esp32:esp32:esp32c5:FlashSize=8M,PartitionScheme=default_8MB,PSRAM=enabled"
CORE_URL="https://github.com/espressif/arduino-esp32/releases/download/3.3.4/package_esp32_dev_index.json"
export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$LIBS" "$OUT"

step(){ echo; echo "========== $* =========="; }

# 1) arduino-cli
if ! command -v arduino-cli >/dev/null 2>&1; then
  step "Installing arduino-cli"
  curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | BINDIR="$HOME/.local/bin" sh
fi
arduino-cli version

# 2) config + core
step "Configuring board manager + installing esp32 core @3.3.4"
arduino-cli config init --overwrite >/dev/null
arduino-cli config set library.enable_unsafe_install true
arduino-cli config add board_manager.additional_urls "$CORE_URL"
arduino-cli core update-index
arduino-cli core install esp32:esp32@3.3.4
arduino-cli core list

# 3) libraries (git clone at pinned refs)
clone(){ # repo ref dest
  local dest="$LIBS/$3"
  [ -d "$dest" ] && { echo "have $3"; return; }
  echo ">> $1 @ $2"
  git clone --quiet --depth 1 --branch "$2" "https://github.com/$1" "$dest"
}
step "Cloning libraries"
clone marian-craciunescu/ESP32Ping          1.6      ESP32Ping
clone ESP32Async/AsyncTCP                    v3.4.8   AsyncTCP
clone stevemarple/MicroNMEA                  v2.0.6   MicroNMEA
clone ESP32Async/ESPAsyncWebServer           v3.8.1   ESPAsyncWebServer
# Mini v3 is ESP32-C5 WITH a screen -> needs the C5-capable TFT_eSPI fork
# (same one the other C5+screen boards use), not stock Bodmer V2.5.34.
clone H4W9/TFT_eSPI                          ESP32-C5 TFT_eSPI
clone PaulStoffregen/XPT2046_Touchscreen     v1.4     XPT2046_Touchscreen
clone lvgl/lv_arduino                        3.0.0    lv_arduino
clone Bodmer/JPEGDecoder                     1.8.0    JPEGDecoder
clone h2zero/NimBLE-Arduino                  2.3.8    NimBLE-Arduino
clone adafruit/Adafruit_NeoPixel            1.12.0    Adafruit_NeoPixel
clone bblanchon/ArduinoJson                 v6.18.2   ArduinoJson
clone ivanseidel/LinkedList                 v1.3.3    LinkedList
clone plerup/espsoftwareserial              8.1.0     EspSoftwareSerial
clone adafruit/Adafruit_BusIO               1.15.0    Adafruit_BusIO
clone adafruit/Adafruit_MAX1704X            1.0.2     Adafruit_MAX1704X
# bundled in repo:
[ -d "$LIBS/Adafruit_TCA8418" ] || cp -r "$ROOT/libraries/Adafruit_TCA8418" "$LIBS/Adafruit_TCA8418"

# 4) TFT_eSPI User_Setup: copy repo's User_*.h in, select the mini setup
step "Configuring TFT_eSPI User_Setup (Marauder Mini)"
cp "$ROOT"/User*.h "$LIBS/TFT_eSPI/"
sed -i -e 's|^#include <User_Setup.h>.*|//#include <User_Setup.h>|' \
    -e 's|^//\{0,1\}#include <User_Setup_marauder_mini.h>.*|#include <User_Setup_marauder_mini_v3.h>|' \
    "$LIBS/TFT_eSPI/User_Setup_Select.h"
grep -Fqx '#include <User_Setup_marauder_mini_v3.h>' "$LIBS/TFT_eSPI/User_Setup_Select.h" \
    || { echo "ERROR: failed to select mini User_Setup"; exit 1; }

# 5) platform.txt patch for 3.3.4 (-zmuldefs, disable C++ exceptions)
step "Patching platform.txt / cpp_flags"
for i in $(find "$HOME/.arduino15/packages/esp32/hardware/esp32/" -name platform.txt); do
  sed -i 's/compiler.c.elf.extra_flags=/compiler.c.elf.extra_flags=-Wl,-zmuldefs /' "$i"
done
for f in $(find "$HOME/.arduino15/packages/esp32/tools/esp32-arduino-libs/" -name cpp_flags 2>/dev/null); do
  sed -i 's/-fexceptions/-fno-exceptions/g' "$f"
done

# 6) compile
step "Compiling esp32_marauder.ino for Mini v3"
arduino-cli compile \
  --fqbn "$FQBN" \
  --warnings none \
  --build-property "compiler.cpp.extra_flags=-DMARAUDER_MINI_V3" \
  --libraries "$LIBS" \
  --output-dir "$OUT" \
  "$SKETCH"

step "DONE"
ls -l "$OUT"/*.bin
echo "Primary app image: $OUT/esp32_marauder.ino.bin"
