# The carrier's display and touch

Paths with no repository prefix are in `coyopedal/`; the forks are named where they are meant.

## Display plan (2026-10-12)

The panel is a 2.8" 240x320 SPI module the vendor drives with TFT_eSPI's ST7789 driver in BGR
order at 80 MHz (their sheet says ILI9341V). Touch is an FT6336U on the shared I2C bus (SDA 2,
SCL 1) with no INT or reset routed to the socket. The carrier routes no backlight or reset GPIO
either: BL is on, RST follows EN.

Pieces, in the order they are needed:

1. **Hardware.** (Pins 0, 19 and 20 have been lifted since before first light; only the
   jumpers remain.) Lift dev-board pins 0, 19 and 20 (BOOT stays the footswitch, the native USB
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

## Measuring what the display costs (plan, 2026-10-12)

The upstream author measured the display stack's cost on the AMOLED 2.41 in the pedal repo's
`docs/S3_DISPLAY_OFF_2026-09-28.md`: an audio-only image against the production image, same
board, same model and preset, deterministic synthetic input, eight effect masks, three
five-second profiles per cell, a 60-second soak, memory and section sizes, and SHA-256 of
every image. We repeat that method on the kit with our own before and after, so the panel's
cost on this board is a number next to his, not a feeling.

**Before** is the headless `lafvin` image, **after** is `lafvin-display` with the panel idle
(UI drawn, nobody touching it), which is what upstream measured. Both must be built on the
same framework stack or the comparison measures the stack bump as well: build the headless
image through the fork CLI and the side stack too (same command as `build-environment.md`
with `--board lafvin` and its own build root), and keep the diagnostic Wi-Fi additions out of
both. Record the sdkconfig diff between the two builds; only display-related lines may differ.

Instruments, all over the maintenance API, so the Wi-Fi join is a prerequisite:

1. `npm run remote -- --host IP effects-profile --seconds 5 --input synthetic --output
   measurements/<date>/<image>-<n>-profile.json`, three times per image. Each run covers the
   seven single-effect masks and the full chain; the table reports the mean per cell and the
   limiting-stage reduction as upstream does.
2. `npm run remote -- --host IP effects-soak --seconds 60 --production --output ...` once
   per image: frames captured, core 0 and core 1 mean and max, silence, trims, drops, USB
   errors, deadline misses.
3. `status` during profiling for free internal SRAM and the largest free block; the build
   log for image size; `xtensa-esp32s3-elf-size -A` on the ELF for `.iram0.text`,
   `.dram0.data`, `.dram0.bss`, `.ext_ram.bss`, `.rtc.force_fast`.
4. SHA-256 of both ELFs and binaries, kept with the raw JSON under `measurements/<date>/`
   in this repository.

Controls as upstream: CPU 240 MHz, 48 kHz, 64-frame blocks, NAM split 8, factory model 0,
preset 0, the same eight masks, radios off during every audio window (`AUDIO TRY` does that).
Differences to state in the write-up: the interface is the MOMIX CAB through UAC1 rather than
the XTONE Pro through UAC2, and the panel is a 240x320 SPI TFT rotated at flush time rather
than a QSPI AMOLED, so the idle cost includes the panel push task on core 1. A second "after"
with the UI being scrolled is optional and separate; upstream did not measure it.

The write-up goes in `docs/display-cost.md` here, in his table layout, with a pointer from
the pedal repo only if the numbers end up in a PR.

## First render (2026-11-14)

Written up 2026-11-18 from the day's commits, the boot logs in `tmp/tmpdir/display-boot-20261114*.log`
and the image index. The jumpers (MOSI to 16, D/C to 17) were soldered by 2026-11-13. They were
powered for the first time this day, and the panel draws through them.

**Stack.** The Oct 12 display image no longer fit. Its first boot today ran out of internal RAM:
the NAM history failed to allocate, and so did the ST7789 staging band. The display variant was
rebuilt on upstream's 0.1.108 stack (core 0.1.49) with three fork topics:
- track B, cut fresh as `composed-st7789-spi` in cli, targets and core;
- track A (no audio chip declared, so the ES8311 stopgap leaves the display definition: pedal `5296d0b`);
- track H.

They are merged into the `pedal-lafvin-display` integration branches of cli and targets (worktrees
`cli-pedal-lafvin-display/` and `targets-pedal-lafvin-display/`), with chips taken from core's
`composed-st7789-spi`.

**Getting the panel to fit, in five builds:**

1. `5296d0b`: the panel's staging band asked for 52,480 bytes and failed. The display block in
   `package.json` was inheriting the AMOLED's native 410x502, because an app define silences the
   composer's board define.
2. `00d6ae8` sets the native 240x320 in the display block, and adds the WPA3 compatibility opt-out
   the headless block already carries. Wi-Fi joins, but a 64-row band still does not fit.
3. targets `09a0a90` adds `GEA_ST7789_FLUSH_ROWS`, and pedal `55a52e9` sets 16 rows, which makes
   a band 7,680 bytes.
4. A fallback that put the panel push task's stack in PSRAM (targets `0f8a50e`) made the panel
   initialise, but every flush then failed in `panel_st7789_draw_bitmap` with `ESP_ERR_NO_MEM`.
   It was reverted (`4ec3329`).
5. Instead, the push task's internal stack is held while the staging ring allocates (`3b2eede`).
   That is the first render.

**The first render** (`images/lafvin-display-20261114-55a52e9-first-render`):
- The staging ring is reduced to 1 of 4 bands under RAM pressure.
- `display ready native=240x320 logical=320x240`; the first flush covers the full frame.
- The UI census reads 15 nodes and 10,181 lit pixels; the render stack has 30,424 bytes of headroom.
- The FT6336 initialises polled on I2C (SDA 2, SCL 1), with no reset or INT line on the carrier,
  as expected.
- Wi-Fi joins the main network; the footswitch line reads `footswitch on GPIO0 ready`.

Not yet recorded as checked by eye: orientation, colour order and inversion. Touch has not been
exercised. Both are the next bench items.

**Audio does not fit beside the display.** The pedal falls back to maintenance ("Audio could not
start"). This is the same signature as the 4.3B before tracks J and K:
- The history planner fails with 9 rings unallocated, totalling 27,888 bytes.
- The model is rejected (`S3-native runtime allocation failed`).
- Internal RAM at NAM load (`internal DMA reserve released`) is free 60,832 with the largest
  block 31,744. The headless 0.1.108 image on 2026-10-23 had free 70,472 with the same largest
  block, and its graph places.

So the display build costs about 9.6 KB of internal RAM before NAM loads. The display itself
only starts after NAM. To recover it:

- **FT6336 controller (about 4.3 KB, measured).** Its static instance is 4,268 bytes in internal
  DRAM in the first-render ELF (`nm -S`), because `ft6336_controller.h` holds a static
  4,096-byte task stack. This is the shape track J fixed for the GT911 (honour
  `GEA_EMBEDDED_TOUCH_TASK_STACK_EXTERNAL`: controller in PSRAM, heap stack there). A J-shaped
  topic for the FT6336 recovers about half the gap. It is a polled touch task, so a PSRAM
  stack is safe; the push-task failure above was an SPI DMA path, not this.
- **Measured on one stack (added 2026-11-18).** The headless 0.1.108 build's ELF and map
  were still in `.gea/build` and are now saved beside its image
  (`images/lafvin-20261023-9029ad0-stack-0.1.108.{elf,map}`). Internal static RAM is
  9,162 bytes larger in the display build, which is the whole gap. All of it is
  `.dram0.data` (+11,856, less 2,160 of `.dram0.bss`). By object file:
  - **The compiled UI app, +6,788** (`libgea_active_geatsc.a`): many small initialised
    objects, none over 512 bytes. Moving these means a placement attribute or PSRAM for the
    app's statics in the compiler's output, which is Geastack's to shape.
  - **The FT6336 controller, +4,268**: the item above.
  - **The ST7789 `DisplayBackend::instance()` backend, +2,232**: a static instance, the same
    pattern as the touch controller, and a candidate for the same PSRAM treatment.
  - Offsets: `display_headless` (-965) and `audio_buffer_runtime` (-1,584) leave.

  The FT6336 and ST7789 statics together recover about 6.5 KB of the 9.2 KB. On the 4.3B,
  9.3 KB recovered was enough for the graph to place. So either both statics plus about
  3 KB of the UI app's data are needed, or the graph places a little short of the full gap;
  only a build will tell. The locale tables suspected from the cross-stack diff are in both
  builds, so they are not part of it.
