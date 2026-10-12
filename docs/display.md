# The carrier's display and touch

Paths with no repository prefix are in `coyopedal/`; the forks are named where they are meant.

## Display plan (2026-10-12)

The panel is a 2.8" 240x320 SPI module the vendor drives with TFT_eSPI's ST7789 driver in BGR
order at 80 MHz (their sheet says ILI9341V). Touch is an FT6336U on the shared I2C bus (SDA 2,
SCL 1) with no INT or reset routed to the socket. The carrier routes no backlight or reset GPIO
either: BL is on, RST follows EN.

Pieces, in the order they are needed:

1. **Hardware.** Lift dev-board pins 0, 19 and 20 (BOOT stays the footswitch, the native USB
   pair stays the host port). Jumper the panel's MOSI and DC pads to two camera pins with the
   ribbon unplugged, GPIO 16 and 17 for example. GPIO 3 and 46 stay with the ES8311 stopgap
   until upstream track A removes the need for it; the composer rejects pin collisions, so the
   definition cannot name them twice. SCK 21 and CS 47 stay as wired.
2. **Composer (cli, track B).** Accept `chips.display.interface: "spi"` with driver `st7789`:
   pins `mosi`, `sclk`, `cs`, `dc`, optional `reset` and `backlight`; `width`, `height`,
   `pclkHz`, `spiMode`, `colorOrder` (rgb|bgr), `invertColors`, the four gap values. Emit
   `St7789DisplayConfig` in `board.h`, the `GEA_ST7789_*` definitions, and
   `GEA_CUSTOM_TARGET_DISPLAY_INTERFACE=spi` in `target.cmake`.
3. **Base target (targets, track B).** For `spi`, include the sticks3 pipeline instead of the
   QSPI `display.cpp`, plus `esp_driver_ledc`. In the pipeline: colour order and inversion from
   definitions, backlight and reset optional (`GPIO_NUM_NC` skips the LEDC channel and the
   reset line). Upstream will probably want the file moved under `chip_bindings/displays/`
   since two targets already share it by relative `#include`; propose it, do not insist.
4. **Catalog (chips, tracks B and C).** An `st7789` display entry with an `esp32-idf` adapter
   and the configuration list above; the `ft6336` entry gains the same adapter block as
   `ft3168`. Check the touch gate in the base CMake admits `ft6336` the way it admits `gt911`.
5. **This repo.** `boards/esp32-s3-lafvin-multimedia-2.8.json` gains `chips.display` and
   `chips.touch`; `package.json` gets `cssDevicePixelRatio: 1` for the target (320x240 logical
   in landscape; the UI needs 205 rows and the LCD 3.5B runs at about 320x213). Start at 40 MHz
   like upstream's 1.54 board; the vendor's 80 MHz through the GPIO matrix can be tried after
   first light.
6. **Order of truth.** Nothing goes upstream until the panel has drawn and touch has moved a
   slider here. The forks are consumed through the CLI's package-path overrides during that
   time (`../BACKLOG.md`, "Upstream tracks"), never through a patched `node_modules` or a
   `file:` dependency.

What the forks now carry (2026-10-12, branch `lafvin-composed-display` in each):

- **chips**: an `st7789` display entry (`spi` interface; width/height, spiHost, pclkHz, spiMode,
  colorOrder, invertColors, four GRAM gaps, pins mosi/sclk/cs/dc with optional reset and
  backlight) and the `esp32-idf` adapter for `ft6336` with optional reset and interrupt pins.
- **cli**: the composer accepts `interface: "spi"`, emits `St7789DisplayConfig display{...}`
  into `board.h` and the `GEA_ST7789_*` definitions plus the native width/height pair into
  `target.cmake`; pin collisions cover the four SPI lines. Test and fixture
  (`spi-panel-board.json`, the LAFVIN shape) and `docs/spi-panels.md`.
- **targets**: the sticks3 pipeline reads `GEA_ST7789_RGB_ORDER_BGR` and
  `GEA_ST7789_INVERT_COLORS` and skips LEDC when the backlight is `GPIO_NUM_NC`;
  `chip_bindings/displays/st7789.cpp` includes it for composed boards; the base CMake keeps
  the QSPI `display.cpp` out for `spi` as it does for `rgb`. The FT6336 binding maps contacts
  through `mapPanelToViewport`, takes `GEA_EMBEDDED_TOUCH_TASK_PRIORITY` like the FT3168 one,
  and `chip_bindings/touch/ft6336_touchscreen.cpp` answers the Touchscreen surface (the
  AMOLED 2.41's `touch.cpp` now includes it instead of carrying a copy).
- **This repo**: `boards/esp32-s3-lafvin-multimedia-2.8-display.json` (MOSI 16, DC 17, SCK 21,
  CS 47, BGR, 40 MHz, inversion off until first light says otherwise; `ft6336` polled) with
  its `package.json` board block (`cssDevicePixelRatio` 1, logical 320x240 over the native
  240x320) and partition table. The headless definition is unchanged.

## First fork build (2026-10-12, host side)

The display variant builds and links against the forks: 3,486,272 bytes, 17% of the 4 MB
slot free (the headless image is 2.4 MB; the panel pipeline, the Gea runtime loop and the
fonts are the difference). Not yet flashed: the hardware mod has not been done. What the six
attempts taught, each fixed in the place it belonged:

1. The forks' base target needs the compiler 1.0.29 framework stack (core 0.1.40, host 0.1.15,
   engine 0.1.16); the pedal's pinned core 0.1.35 lacks host sources it lists. Rather than bump
   the pedal's lockfile for an experiment, a side install under `gea-stack/` feeds the CLI's
   package-path overrides (`build-environment.md`). The pedal's native code compiled against
   the newer framework without a change, so the eventual bump should be uneventful.
2. The compiler must be exactly the locked 1.0.29, not the newest 1.0.x.
3. The ST7789 pipeline and the RGB binding lacked `Display::flushOdometerRead`, which core's
   display contract declares and the pedal's soak test reads; added to both (targets `f65c525`).
4. The source walk that feeds code generation did not prune `.gea`, so a build root named
   anything but `build` found the generated vite bundle as a source of itself on reconfigure
   and ninja refused the cycle (targets `d107bfb`).
5. Both aliases write the same `build/pedalboard.bin`; see `build-environment.md`.
