# The Waveshare ESP32-S3-Touch-LCD-4.3B (rev1.1) gift (track F)

A composed-board definition for `@geastack/targets`. I *thought* this was the board an Issue in @dashersw/coyopedal had mentioned, and left a comment on that Issue explaining why what they were trying wouldn't work, though it turned out the were actually using the P4 equivalent to this board.

Anyway, since we noticed there was already support for the 7" sibling to this board, 
(and we now have both the S3 and P4 versions of this kit), we wanted to send this easy win composition as a sort of gift and as an introduction to the other PRs forthcoming (in @geastack and the @dashersw/coyopedal trees) in related to the work of getting coyopedal onto a LAVFIN board that was around and unused.

Verified against the board 2026-10-15. The point of the track is a small, clean PR against upstream's own stack.

## What the branch carries

Fork `targets`, branch `waveshare-touch-lcd-4.3b`, rebased on upstream main (`9546973`, the
0.1.102 release plus the Windows test fixes) before verification. Three files:

- `targets/esp32-s3-waveshare-touch-lcd-4.3b.json`: the 7-inch definition (same ST7262
  800x480 RGB panel, GT911, CH422G, pin for pin) with the geometry checked against the wiki
  and the notes rewritten for what the B adds off the panel (RS485 on UART0, CAN, isolated
  I/O on the expander's spare lines, PCF85063 RTC, lithium charger), registered in
  `targets.json`.
- `build-config.json`: an entry like the upstream 4B board's (`cssDevicePixelRatio` 1, O2,
  Wi-Fi auto). Without one the CLI falls back to the `esp32-s3` base entry and lays the UI
  out at 1.5, which the first build showed: the counter starter's buttons sat on the bottom
  edge of the 800x480 panel.
- `docs/WAVESHARE-LCD-4.3B.md`: the board page in the voice of the maintainer's 4B page,
  with the verification record.

## The bench

Separate from the pedal and its forks (which stay on `lafvin-composed-display`):

- `targets-4.3b/`: a git worktree of the targets fork on the gift branch.
- `core-main/`: a detached worktree of core at upstream main, for `packages/chips`.
- `tmp/counter-43b/`: `gea create counter-43b --starter counter --yes` with the fork CLI; the
  scaffold installs the published stack into its own `node_modules` (cli 0.1.102, targets
  0.1.103, chips 0.1.6, core 0.1.42, compiler 1.0.33, engine 0.1.17), so the build runs on
  upstream's packages with only the targets root and the chips directory overridden. Alias
  `lcd43b` in the app's `.gea/boards.json` (native USB-Serial/JTAG, serial
  `44:1B:F6:C8:B0:4C`).

```sh
A=/Volumes/idf6/pedalboard/tmp/counter-43b
IDF_TOOLS_PATH=/Volumes/idf6/.espressif-idf6 \
GEA_TARGETS_ROOT=/Volumes/idf6/pedalboard/targets-4.3b \
GEA_CHIPS_DIR=/Volumes/idf6/pedalboard/core-main/packages/chips \
node $A/node_modules/@geastack/cli/bin/gea.mjs build --board lcd43b --app counter-43b --project $A
# then: flash --no-build, screenshot shot.png --transport usb, devctl state|tap x y
```

Always pass `--app` and `--project`: the board builds one app at a time, and the harness
working directory drifts between parallel commands.

## What was learned

- The board on the port is what the definition assumes: ESP32-S3 revision v0.2, 8 MB
  embedded octal PSRAM (AP, generation 3), 16 MB quad flash, USB-Serial/JTAG mode.
- The composer renders the definition unchanged into `board.h` (all sixteen data lines, the
  four sync signals, 16 MHz, 4/8/8 timings, pclk active-low, GT911 INT 4 with reset through
  the expander, CH422G outputs 0x1e). `target.cmake` links `rgb_panel.cpp`, the GT911 and
  CH422G bindings and their portable cores, nothing else.
- First boot (2026-10-15, the 1.5-ratio image): PSRAM test OK, `CH422G ready (IO0-7
  outputs=0x1e)`, `RGB panel ready 800x480 pclk=16000000 bounce_rows=20`, `GT911 found at
  0x5d`, interrupt-driven, the app at 62.5 fps with the display taking 15.8 of the 16 ms
  frame. The screenshot over USB (`gea screenshot --transport usb`) shows the counter; two
  `devctl tap` injections on the plus button counted to 2.
- The targets tests pass from a fresh checkout of the branch after `npm ci` (one test,
  `touch-report`, wants a device build directory and fails anywhere without one). But a
  `node_modules` inside the targets root makes the CLI hang in board resolution when
  `GEA_TARGETS_ROOT` points there: it crawls the tree. Move it aside before building.
- `gea build` resolves the board alias over USB before it starts; a screenshot or devctl
  command holding the port at that moment is harmless, but the resolution is slow (about
  twenty seconds against a checkout).
- The ratio-1 image (with the `build-config.json` entry) boots the same, 2.2 MB, and the
  screenshot's content centre moves to (427, 268): the 28 px padding offset, as predicted.
- Rebuilt and reflashed on 2026-10-16 after the branch was brought up to upstream's current
  main (`b5a6a28`, four commits on from the rebase, including the component-solving change to
  the base target): same boot, same panel and touch lines, 2.2 MB. The PR's verification claim
  holds for the tree he will merge.
- Nothing in the definition needed changing after hardware. What the B adds off the panel
  (RS485, CAN, isolated I/O, RTC, charger) stays undescribed by design: the composer has no
  roles for them.

- Fingers on the glass: the user came back to the bench to find the panel showing the counter
  at 2 (the injected taps) and the minus and plus buttons answering touch. Panel, GT911 and
  the reset-through-expander path all confirmed by hand, 2026-10-15.

- The counter sits low and right of centre on the panel, and the USB screenshot shows the same:
  content centre at (441, 284) in the 800x480 frame on the 1.5-ratio image, an offset of 42 px
  on both axes, which is the starter stylesheet's `padding: 28px` times 1.5. `.screen` is
  `100vw` by `100vh` plus padding under content-box sizing, so the box overflows the viewport
  by the padding and its centred children land one padding to the right and down, exactly as
  a browser would lay it out. The panel scans the framebuffer faithfully; the starter wants
  `box-sizing: border-box`. Not the board's business, worth a word to the maintainer.

## Not verified

- Wi-Fi, OTA, the microSD slot (SPI, not declared), audio (none on the board).

## Track G: the card slot on SPI (2026-10-16)

The pedal loads every model from the card, and the 4.3B's slot is SPI (MOSI 11, SCK 12,
MISO 13) with the chip-select on the CH422G's EXIO4; the composer knew only SD_MMC 1-bit and
the base mounted only through the SDMMC host, so the pedal could not have booted on the
board. The second gift, two repositories, branch `composed-spi-microsd` in each (worktrees
`cli-spi-sd/` off upstream main and `targets-spi-sd/` off upstream main plus the gift
commit, so the 4.3B definition exists to declare the slot on):

- CLI, `src/boards/custom-target.mjs`: `storage.microSD.interface` takes `spi` beside
  `sdmmc-1bit`: `spiHost` (`spi2`/`spi3`), `maxFreqKhz` (400 to 40000, default 20000), pins
  `mosi`/`miso`/`sck`, and one select line, either `pins.cs` (a GPIO) or
  `chips.expander.outputs.cardSelect`. Both or neither is an error, as is a `cardSelect` with
  no storage. The header gains `GEA_BOARD_MICROSD_SPI`, an `SdSpiConfig storageSpi` constant
  and a `cardSelect` member on `IoExpanderConfig`; the SD_MMC constants stay (the base checks
  them for NC). The CMake fragment names the interface and asks for `esp_driver_sdspi` and
  `esp_driver_spi`. Tested in `test/boards.test.mjs` (header, CMake, the error cases, a lane
  clash); the setup guide's composed-targets section documents the role.
- targets, the base's `sdcard_mount.cpp`: a `GEA_BOARD_MICROSD_SPI` branch that holds the
  expander's select line low, brings the SPI bus up (tolerating a bus a panel already
  initialised, for the ST7789 boards where the card may share SPI2), and mounts through
  `esp_vfs_fat_sdspi_mount` with `SDSPI_SLOT_NO_CS` when the select is on the expander. The
  4.3B and the 7-inch definitions declare the slot and `cardSelect: 4`; the board page says so.

Why the select line is held low rather than toggled: the card is the only device on that
bus, and Waveshare's own ESP-IDF demo for the family (`03_SD_Test`, `sd_card.c`) writes the
CH422G output latch with EXIO4 low and hands the SDSPI slot `CONFIG_EXAMPLE_PIN_CS=-1`, on
SPI2 at the default 20 MHz with `max_transfer_sz` 4000. The ESP-IDF driver supports it
explicitly (`SDSPI_SLOT_NO_CS`).

What this does not cover: the pedal mounts the card itself in `src/native/storage/sd_models.cpp`
through the SDMMC host, reading `board::storage.clk` and friends, because it unmounts and
remounts to rescan. For the pedal on the 4.3B that file gains the same SPI branch keyed on
`GEA_BOARD_MICROSD_SPI`, in the pedal fork, after this track lands.

Verification: `gea devctl push <file> /sdcard/<name>` over USB triggers the lazy mount from any
app, so the counter starter serves; the log line to look for is `mounted /sdcard (SDSPI)`.
Two things about that path, learned 2026-10-16 on the empty slot: the base attempts the mount
once per boot and caches a failure, so insert the card and reset before testing; and the CLI
swallows the device's log lines during a push, so the mount's own lines (`mounting /sdcard
SDSPI host=1 mosi=11 miso=13 sck=12 cs=-1 20000 kHz`, then the result) are only seen by
driving `GEADEV PUSH` from a serial script. With no card: the expander asserts EXIO4 without
error, the bus comes up, `sdmmc_card_init` times out (0x107) and the push answers
`no-storage`. The counter image with the SDSPI host is 84 KB larger (0x232c80 bytes).

Verified 2026-10-16 with a FAT32 card in the slot: reset, `GEADEV PUSH /sdcard/hello.txt 60
<crc>` answers `PUSH READY` after `mounting /sdcard SDSPI host=1 mosi=11 miso=13 sck=12 cs=-1
20000 kHz` and `mounted /sdcard (SDSPI)` (300 ms from attempt to mount), then `PUSH OK` with the
CRC matched; `GEADEV LS /sdcard` lists the file at 60 bytes beside the Mac's Spotlight
folders. Both gifts have now run on the board; both branches wait on the user's commit and
push, the targets one stacked on the gift commit until that PR merges.
