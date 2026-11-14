<!---[![License: MIT](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/justcallmekoko/ESP32Marauder/blob/master/LICENSE)--->
<!---[![Gitter](https://badges.gitter.im/justcallmekoko/ESP32Marauder.png)](https://gitter.im/justcallmekoko/ESP32Marauder)--->
<!---[![Build Status](https://travis-ci.com/justcallmekoko/ESP32Marauder.svg?branch=master)](https://travis-ci.com/justcallmekoko/ESP32Marauder)--->
<!---Shields/Badges https://shields.io/--->

# ESP32 Marauder
<p align="center"><img alt="Marauder logo" src="https://github.com/justcallmekoko/ESP32Marauder/blob/master/pictures/marauder_skull_patch_04_full_final.png?raw=true" width="300"></p>
<p align="center">
  <b>A suite of WiFi/Bluetooth offensive and defensive tools for the ESP32</b>
  <br><br>
  <a href="https://github.com/justcallmekoko/ESP32Marauder/blob/master/LICENSE"><img alt="License" src="https://img.shields.io/github/license/mashape/apistatus.svg"></a>
  <a href="https://gitter.im/justcallmekoko/ESP32Marauder"><img alt="Gitter" src="https://badges.gitter.im/justcallmekoko/ESP32Marauder.png"/></a>
  <br>
  <a href="https://twitter.com/intent/follow?screen_name=jcmkyoutube"><img src="https://img.shields.io/twitter/follow/jcmkyoutube?style=social&logo=twitter" alt="Twitter"></a>
  <a href="https://www.instagram.com/just.call.me.koko"><img src="https://img.shields.io/badge/Follow%20Me-Instagram-orange" alt="Instagram"/></a>
  <br><br>
</p>
    
[![Build and Push](https://github.com/justcallmekoko/ESP32Marauder/actions/workflows/build_push.yml/badge.svg)](https://github.com/justcallmekoko/ESP32Marauder/actions/workflows/build_push.yml)
[![Firmware coverage](https://codecov.io/gh/justcallmekoko/ESP32Marauder/branch/develop/graph/badge.svg?flag=firmware-unit-tests)](https://app.codecov.io/gh/justcallmekoko/ESP32Marauder/tree/develop)

## Getting Started
Download the [latest release](https://github.com/justcallmekoko/ESP32Marauder/releases/latest) of the firmware.  

Check out the project [wiki](https://github.com/justcallmekoko/ESP32Marauder/wiki) for a full overview of the ESP32 Marauder

### Mini v3 automatic Wardriving

The Mini v3 build starts Wardriving on boot after it detects the GPS module and gets a location fix. While it waits, press the center (**C**) button to skip to the normal menu. If the GPS module is not detected, the normal menu opens instead. **Wardriving** is also the first main-menu action when the GPS module is present, so it can be started again without rebooting.

A session alternates Wi-Fi access-point scans, short Wi-Fi probe listening windows, and BLE scans. With a GPS fix and outside a paused geofence, it saves access points and BLE advertisements to `wardrive_*.log`, and directed probe requests with a nonempty network name to `wombat_probes_*.csv` on the SD card. Probe rows include the transmitting device's observed MAC address, requested network name, signal strength, time, and location. This is useful for finding possible links between devices and network names; it does not record general Wi-Fi station-to-AP associations or prove that a device joined an AP. Radio timing and channel hopping mean some probes will be missed; MAC randomization makes device matching less certain.

### Wombat uploads (Mini v3)

Save a 64-character hex Wombat device-upload token as `/wombat_token.txt` on the Mini v3 SD card. Save the Wombat server's hostname, without `https://`, a port, or a path, as the first line of `/wombat_host.txt` on the same card. Keep both files out of Git. The server must have a valid HTTPS certificate chaining to ISRG Root X1. Save a Wi-Fi profile on the device, then use **WiFi > Upload Wardrive Logs > Wombat** for one log or **Upload All > Wombat** for pending logs. Marauder sends its WiGLE-format `wardrive_*.log` files with `.csv` upload names to the configured host's `/api/device-upload` endpoint; Wombat deduplicates identical files, and Marauder marks successful files with `.wombat` sidecars. The device clock must sync over Wi-Fi for HTTPS validation. The Mini v3 build uses the public ESP32-C5 display and pin setup from [Marauder Eternal MiniV3](https://github.com/n0vajay05/ESP32MarauderEternal-MiniV3). An application-only image built from this tree booted on an ESP32-C5 rev 1 Mini v3 with 8 MB flash, and on November 5, 2026 its Upload All action imported nine logs and 431 observations into Wombat (one log contained no observations).

The Mini v3's one-tap **Wardriving** session also saves directed, named probe requests with a GPS fix to a separate `wombat_probes_*.csv` file on the SD card. **Upload All > Wombat**, `upload -d wombat`, and auto-upload include these files; WiGLE and WDG uploads keep using the ordinary AP/BLE wardrive logs. Wombat imports the probe rows as `WIFI-PROBE`. Empty-name probes are not useful for AP-name matching and are not logged. The radio listens on one channel at a time, so a session cannot capture every probe request.

### Import Wi-Fi networks from the SD card

To avoid entering a password with the Mini's buttons, create `/wifi_import.json` at the SD card root before booting. It accepts one to five networks:

```json
{"networks":[{"ssid":"Example WiFi","psk":"example-password"}]}
```

On boot, the Mini v3 imports these profiles into its existing saved-Wi-Fi settings, then reads the settings back from device flash. It removes the SD file only when every profile matches. If the file is invalid, there are too many profiles for the five saved slots, saving fails, or SD removal fails, it reports the reason over serial and leaves the file for correction. Existing profiles with the same SSID are updated. Importing does not test the network connection; **Join Saved WiFi** or **Upload All > Wombat** will try the saved profile later. Passwords must be 8–63 characters, and SSIDs must be 1–32 bytes. Keep the JSON file out of Git and delete any copies made on your computer. Removing the SD file is not a secure erase of its flash blocks, and the saved profiles remain in the Mini's device flash.

### Build and install the Mini v3 firmware

This tree contains the Mini v3 hardware definition, so the external MiniV3 fork is not needed to recover its display pins. Keep `User_Setup_marauder_mini_v3.h`, `esp32_marauder/configs.h`, and `build/build_mini_v3.sh` with the source when committing or archiving this project. The hardware setup uses an ST7735 128×128 display on the ESP32-C5 SPI pins (MISO 2, MOSI 7, SCLK 6, CS 23, DC 24, backlight 5); the SD card uses CS 10. Do not select the original Mini setup: it caused a boot loop on this Mini v3. The `MARAUDER_MINI_V3` config enables GPS, SD, Bluetooth, PSRAM, and boot to wardriving. The main menu also has **Wardriving** at the top when the GPS module is present.

From the repository root on Linux, run `bash build/build_mini_v3.sh`. The script installs Arduino CLI if needed, installs Espressif Arduino core **3.3.4**, clones the library versions listed in the script into ignored `build/libraries/`, selects this repository's Mini v3 TFT setup in the ESP32-C5-capable `H4W9/TFT_eSPI` fork, and compiles `esp32_marauder/esp32_marauder.ino`. It uses board `esp32:esp32:esp32c5`, **8 MB flash**, `default_8MB` partitions, **PSRAM enabled**, and `-DMARAUDER_MINI_V3`. The app image is `build/out/esp32_marauder.ino.bin`. The script applies linker/exception compatibility edits to the installed ESP32 core, so run it in a dedicated Arduino environment if that core is also used for other projects. The [upstream source-install guide](https://github.com/justcallmekoko/ESP32Marauder/wiki/installing-firmware-from-source) provides general Arduino IDE setup; this Mini v3 recipe supplies the board-specific settings.

For later builds with the libraries already installed, the equivalent compile command is:

```sh
arduino-cli compile \
  --fqbn 'esp32:esp32:esp32c5:FlashSize=8M,PartitionScheme=default_8MB,PSRAM=enabled' \
  --warnings none \
  --build-property 'compiler.cpp.extra_flags=-DMARAUDER_MINI_V3' \
  --libraries build/libraries \
  --output-dir build/out \
  esp32_marauder/esp32_marauder.ino
```

Before flashing, confirm the connected chip is an **ESP32-C5** with **8 MB** flash and save a full backup. Replace `<PORT>` with the device's stable `/dev/serial/by-id/...` path. Keep the backup outside Git; it may contain device settings and credentials. Only write the app at `0x10000` when the device already has the matching `default_8MB` bootloader and partition table. This preserves NVS, SPIFFS, and SD contents.

```sh
esptool --chip esp32c5 --port '<PORT>' flash-id
esptool --chip esp32c5 --port '<PORT>' read-flash 0x0 0x800000 mini-v3-backup.bin
esptool --chip esp32c5 --port '<PORT>' --baud 460800 write-flash 0x10000 build/out/esp32_marauder.ino.bin
```

Check for esptool's verified hash, then confirm on the device that the display boots, the buttons navigate, and **Wardriving** appears first on the main menu and opens the scan screen. A successful compile or flash verification alone does not prove the display and controls work.

## FCC module identifiers

The Device Info screen reports the FCC ID of the radio module fitted to supported JustCallMeKoko hardware. This is the module identifier, not a claim that every carrier-board or enclosure configuration has a separate end-product grant.

| Hardware | Radio module | FCC ID |
| --- | --- | --- |
| Marauder v8, Marauder Mini v3, C5 Wardriver, C5 LowKey, BFFB v2 | ESP32-C5-WROOM-U | `2AC7Z-ESPC5WROOMU` |
| Marauder v4, v6, v6.1, v7, original Mini, Marauder Kit | ESP32-WROOM-32U | `2AC7Z-ESP32WROOM32U` |
| BFFB / Marauder Dev Board Pro | ESP32-WROOM-32E | `2AC7Z-ESP32WROOM32E` |

The legacy mappings are the closest modular approvals for the modules specified by the repository hardware designs. Confirm the module marking on a physical unit before using an FCC ID for labeling or compliance documentation. Third-party targets display `See hardware label` because their module or complete-device certification can vary by production revision.

# For Sale Now
You can buy the ESP32 Marauder using [this link](https://www.justcallmekokollc.com)
