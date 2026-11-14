#!/usr/bin/env bash
# Fix: swap stock TFT_eSPI (no ESP32-C5 support) for the C5-capable fork, recompile.
# Core, other libs, and platform.txt patch are already in place from the first run.
set -euo pipefail

# Require the exact Mini v3 hardware setup; the original Mini setup bootloops on this device.
if [[ ! -f "$(dirname "$0")/../User_Setup_marauder_mini_v3.h" ]]; then
  echo "Mini v3 build stopped: exact Mini v3 display/pin setup is unavailable." >&2
  echo "The original Mini setup bootloops on ESP32-C5; do not flash that build." >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIBS="$ROOT/build/libraries"
OUT="$ROOT/build/out"
SKETCH="$ROOT/esp32_marauder/esp32_marauder.ino"
FQBN="esp32:esp32:esp32c5:FlashSize=8M,PartitionScheme=default_8MB,PSRAM=enabled"
export PATH="$HOME/.local/bin:$PATH"

echo "== Replacing TFT_eSPI with H4W9/TFT_eSPI @ ESP32-C5 =="
rm -rf "$LIBS/TFT_eSPI"
git clone --quiet --depth 1 --branch ESP32-C5 https://github.com/H4W9/TFT_eSPI "$LIBS/TFT_eSPI"

echo "== Re-applying Marauder Mini User_Setup =="
cp "$ROOT"/User*.h "$LIBS/TFT_eSPI/"
sed -i -e 's|^#include <User_Setup.h>.*|//#include <User_Setup.h>|' \
    -e 's|^//\{0,1\}#include <User_Setup_marauder_mini.h>.*|#include <User_Setup_marauder_mini_v3.h>|' \
    "$LIBS/TFT_eSPI/User_Setup_Select.h"
grep -Fqx '#include <User_Setup_marauder_mini_v3.h>' "$LIBS/TFT_eSPI/User_Setup_Select.h" \
    || { echo "ERROR: failed to select mini User_Setup"; exit 1; }

echo "== Recompiling =="
arduino-cli compile \
  --fqbn "$FQBN" \
  --warnings none \
  --build-property "compiler.cpp.extra_flags=-DMARAUDER_MINI_V3" \
  --libraries "$LIBS" \
  --output-dir "$OUT" \
  "$SKETCH"

echo "== DONE =="
ls -l "$OUT"/*.bin
