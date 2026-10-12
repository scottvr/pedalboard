# Geastack: composed targets, what is missing, what we changed

Paths with no repository prefix are in `coyopedal/`; the forks are named where they are meant.

## The Geastack packages, as installed and as published

Installed: cli 0.1.89, targets 0.1.87, chips 0.1.4, core 0.1.35, engine 0.1.10, host 0.1.12.
Latest published on 2026-10-08: targets 0.1.98, chips 0.1.6. Neither ships a target for this
kit. There is no Geastack checkout on this machine.

### App-local composed targets (what exists)

- `@geastack/targets` README, "App-local custom targets": a board alias in `.gea/boards.json`
  can point at a JSON definition (`targetDefinition`, path relative to that file) that
  `extends` the composable `esp32-s3` base and names chips from `@geastack/chips/catalog.json`.
  The CLI (`src/boards/custom-target.mjs`) generates `board.h` and `target.cmake` under the
  build directory; the base project is `targets/esp32-s3-touch-amoled-2.06`.
- `.gea/` is gitignored here, so the definition should live in the repo (for example
  `boards/esp32-s3-lafvin-multimedia-2.8.json`) and the alias references it as
  `../boards/...`.
- Definition fields: `flashSize`, `partitions` (no data payloads; the app manifest's
  `partitionsByTarget` wins anyway), `console` (uart 0 here, since the OTG port is the host),
  `psram` (octal, 80), `buses.i2c`, `chips.display` (qspi or rgb only), `chips.touch`
  (needs an esp32-idf adapter in the installed catalog: ft3168, gt911), `chips.power`,
  `chips.imu`, `chips.audio` (es8311 only), `chips.expander`, `storage.microSD`
  (`sdmmc-1bit`), `controls.launcherButton`.
- Generated macros: `GEA_BOARD_HAS_I2C/DISPLAY/TOUCH/POWER/IMU/AUDIO/MICROSD/LAUNCHER_BUTTON/
EXPANDER`, `GEA_EMBEDDED_NO_DISPLAY=1` when there is neither display nor canvas,
  `GEA_BOARD_HAS_POWER` also reaches app sources.
- The base CMake adds the ES8311 binding and `GEA_BOARD_HAS_SPEAKER=1` whenever the app's
  compiler analysis reports an `audio` binding, regardless of the board; the headless build
  must be checked against that.

### What is missing upstream

Checked again 2026-10-12 against targets 0.1.101, cli 0.1.102 and chips 0.1.6 (all three
repositories are public on GitHub under `geastack/`, GPL-3.0, one author, releases most days).
None of the three gaps has closed, but the composer is being extended in exactly this area:
cli `f9038d8` (2026-10-08) added custom QSPI panel profiles, `5414944` (2026-09-22) composed
RGB boards with a GT911 and an I/O expander.

- Display: `src/boards/custom-target.mjs` rejects every `chips.display.interface` except
  `qspi` and `rgb`. The SPI ST7789 pipeline exists as
  `targets/esp32-s3-m5stack-sticks3/main/display.cpp` (1,412 lines; `esp32-s3-touch-lcd-1.54`
  reuses it by `#include` with `GEA_ST7789_*` compile definitions). It reads its pins from a
  `St7789DisplayConfig { spiHost, mosi, sclk, cs, dc, reset, backlight }` in the board header,
  hard-codes `LCD_RGB_ELEMENT_ORDER_RGB` and `esp_lcd_panel_invert_color(true)`, and treats the
  backlight LEDC channel as mandatory. The composed base's `main/CMakeLists.txt` includes the
  QSPI `targets/esp32/display.cpp` for any non-RGB display.
- Touch: `targets/esp32/chip_bindings/touch/ft6336.cpp` exists and is already shaped for
  composition (reads `board::touch.reset` and `.interrupt`, polls at priority 4 when INT is
  `GPIO_NUM_NC`, uses the primary I2C bus), but the chips catalog entry has `"adapters": {}`,
  and the base CMake's touch gate only names ft3168 and gt911.
- Speaker: only the ES8311 binding exists, compiled for every audio-capable app. The ES8311
  binding writes samples through `esp_codec_dev`, so when the codec's I2C open fails nothing
  reaches I2S; the stopgap cannot drive the PCM5100 even by accident. A codec-less I2S DAC
  binding is the I2S half of that file without the codec-dev calls.
- Per AGENTS.md none of this can live in this repo (no board CMakeLists, partition CSV or
  display driver here), and `src/ui/README.md` says why the repo carries no local patches:
  the route is forks of the three repositories, tested here, then PRs.

### Repo changes for milestone 1 (headless): done 2026-10-09

- `boards/esp32-s3-lafvin-multimedia-2.8.json`: extends esp32-s3, 16MB, octal PSRAM 80 MHz,
  console uart 0 at 115200, SDMMC clk 39 cmd 38 data0 40, launcher button GPIO 0 active low, no
  display, no touch, no power; the PCM5100 declared as an ES8311 as a build stopgap.
- `package.json`: the 16 MB partition table (two 4 MB OTA slots) and `GEA_BOARD_HAS_POWER: 0`
  for the LAFVIN and devkit targets.
- `src/native/storage/sd_models.cpp` reads the slot pins from every board's `board.h`
  (`GPIO_NUM_NC` means no slot) instead of hard-coding the AMOLED's 2/1/3.
- Still open: the `.gea/boards.json` alias needs the board's USB serial; README and skill
  updates wait until something has run on hardware. For the display later: native 240 x 320,
  landscape 320 x 240, `cssDevicePixelRatio` 1 (1.5 would leave 160 logical pixels of height
  against the UI's 205 minimum).

## Milestone 1 (headless) status, 2026-10-09

- `boards/esp32-s3-lafvin-multimedia-2.8.json` is the composed definition: headless, 16 MB,
  octal PSRAM, console on UART 0, I2C on 2/1, SDMMC on 39/38/40, BOOT as the launcher button,
  and the PCM5100 declared as an ES8311 on its real I2S pins as a stopgap so Geastack's audio
  binding compiles (its codec init fails over I2C at run time and the speaker stays hidden;
  MCLK, DIN and the amplifier-enable pin the CLI insists on go to GPIO 3, 46 and 15, which
  nothing uses). `package.json` carries its 16 MB partition table and
  `GEA_BOARD_HAS_POWER: 0`, as it now does for the devkit.
- It builds against ESP-IDF 6.0.2: 1,949,024 bytes, 54% of the 4 MB OTA slot free. The alias is
  machine-local in `.gea/boards.json`:

  ```json
  "lafvin": {
    "target": "esp32-s3-lafvin-multimedia-2.8",
    "targetDefinition": "../boards/esp32-s3-lafvin-multimedia-2.8.json",
    "adapter": "esp32-idf",
    "appPlatform": "esp32",
    "flashSize": "16MB"
  }
  ```

  Add `transports.usbSerial.serial` (from `npx gea boards discover`) before flashing, and
  `IDF_TOOLS_PATH=/Volumes/idf6/.espressif-idf6` in the shell. `npx gea build --board lafvin`
  writes `build/pedalboard.bin`; `npx gea flash --board lafvin --monitor` provisions over the
  CH343 port.

- `src/native/storage/sd_models.cpp` now reads the slot pins from every board's `board.h` and
  declines to mount when a board declares none, instead of special-casing two targets and
  hard-coding the AMOLED's pins. Verified by building the AMOLED target (same 3,068,336-byte
  image) and the LAFVIN target.
- Not yet verified on hardware: boot, the stopgap audio failing gracefully, SD, USB host with
  the MOMIX. The dev board must be out of the carrier, or pins 19, 20 and 0 lifted, before any
  USB test.

## Upstream Geastack blockers found on the way (2026-10-09)

1. `GEA_BOARD_HAS_POWER` redefined on composed boards: the generated `board.h` defines it 0
   while the app's root defines pass 1 for the AMOLED default, and `-Werror` stops the build.
   Worked around in `package.json` with a per-target override (a one-line PR for upstream's
   own `s3-devkit`, which has not built since the internal speaker landed).
2. The ES8311 binding is compiled for every audio-capable app whether or not the board has a
   codec, and the composer never emits a has-audio variable. A codec-less composed board cannot
   build. Fix: the CLI's `custom-target.mjs` emits `GEA_CUSTOM_TARGET_HAS_AUDIO`, and the 2.06
   target's CMake falls back to `audio_runtime_stub.cpp` with `GEA_BOARD_HAS_SPEAKER=0` when a
   custom target has no audio chip. Our stopgap (PCM5100 declared as ES8311) goes away then.
3. Already known: no SPI panel driver (ST7789/ILI9341) in the composable base, no FT6336
   touch adapter, no codec-less I2S DAC driver.
