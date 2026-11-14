#!/usr/bin/env python3
"""Regression checks for target-aware PSRAM initialization."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SKETCH = ROOT / "esp32_marauder/esp32_marauder.ino"


class PsramInitializationTests(unittest.TestCase):
    def test_low_level_psram_initializer_is_not_called_directly(self):
        source = SKETCH.read_text(encoding="utf-8")
        self.assertNotIn("esp_spiram_init()", source)

    def test_arduino_psram_initializer_is_guarded_by_board_capability(self):
        source = SKETCH.read_text(encoding="utf-8")
        expected = """#ifdef HAS_PSRAM
    if (!psramInit()) {
      Serial.println(F("PSRAM not available"));
    }
  #endif"""
        self.assertIn(expected, source)

    def test_mini_v3_build_enables_psram(self):
        config = (ROOT / "esp32_marauder/configs.h").read_text(encoding="utf-8")
        mini = config.split("#ifdef MARAUDER_MINI_V3\n", 1)[1].split("#endif", 1)[0]
        self.assertIn("#define HAS_PSRAM", mini)
        for script in ("build/build_mini_v3.sh", "build/fix_tft_and_rebuild.sh"):
            self.assertIn("PSRAM=enabled", (ROOT / script).read_text(encoding="utf-8"))

    def test_mini_v3_scripts_require_the_correct_hardware_setup(self):
        for script in ("build/build_mini_v3.sh", "build/fix_tft_and_rebuild.sh"):
            source = (ROOT / script).read_text(encoding="utf-8")
            self.assertIn("User_Setup_marauder_mini_v3.h", source)
            self.assertIn("#include <User_Setup.h>.*|#include <User_Setup_marauder_mini_v3.h>", source)
            self.assertIn("#include <User_Setup_marauder_mini.h>.*|#include <User_Setup_marauder_mini_v3.h>", source)

    def test_mini_v3_display_and_sd_share_the_c5_spi_pins(self):
        config = (ROOT / "esp32_marauder/configs.h").read_text(encoding="utf-8")
        mini = config.split("    #ifdef MARAUDER_MINI_V3\n      #define CHAN_PER_PAGE", 1)[1].split("    #endif", 1)[0]
        setup = (ROOT / "User_Setup_marauder_mini_v3.h").read_text(encoding="utf-8")
        for name, pin in {"TFT_MISO": 2, "TFT_MOSI": 7, "TFT_SCLK": 6,
                          "TFT_CS": 23, "TFT_DC": 24, "TFT_RST": -1,
                          "TFT_BL": 5}.items():
            definition = f"#define {name} {pin}"
            self.assertIn(definition, mini)
            self.assertIn(definition, setup)
        self.assertIn("#define SD_CS 10", mini)

    def test_c5_sd_shares_spi_bus_without_copying_it(self):
        source = SKETCH.read_text(encoding="utf-8")
        self.assertIn("SPIClass &sharedSPI = SPI;", source)
        self.assertNotIn("SPIClass sharedSPI(SPI);", source)


if __name__ == "__main__":
    unittest.main()
