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

## The pedal on the 4.3B (started 2026-10-16, overnight)

Sprint item 8's second step, in the pedal fork (branch `lavfin-kit-notes`), built against the
track G branches and the published framework stack:

- `boards/esp32-s3-waveshare-touch-lcd-4.3b.json`: the shipped composed definition plus what
  the pedal needs and the gift must not carry: an ES8311 stopgap on GPIO 6, 15, 16, 43 and 44
  (free, CAN, and the RS485 pair, none of them a console here), no launcher button, the SPI
  card slot as upstream declares it. Alias `lcd43b` in `.gea/boards.json`, serial
  `44:1B:F6:C8:B0:4C`.
- `package.json`: a 16 MB partition table for the target (the kit's display layout), a board
  block with `cssDevicePixelRatio` 1 and the 800x480 defines, `GEA_BOARD_HAS_POWER` 0 and the
  gateway's WPA3 compatibility opt-out, and `esp_driver_sdspi` plus `esp_driver_spi` in the
  component requires.
- `src/native/storage/sd_models.cpp`: the pedal mounts the card itself (it unmounts and
  remounts to rescan), so it gains the same `GEA_BOARD_MICROSD_SPI` branch as the base: select
  held low through the expander, SDSPI slot with no CS pin, the bus tolerated if already up.
- `src/native/main/main.cpp`: the footswitch was hard-wired to GPIO 0 ("BOOT is a footswitch
  on every board"). On the 4.3B GPIO 0 is RGB data6, and configuring it as an input with an
  interrupt would take the lane from the panel. The pin now comes from the board's
  `launcherButton`, which every board layer declares, and a board that declares none gets no
  footswitch task. Worth sending upstream on its own: it is the honest reading of the base's
  own convention.

Build: from `coyopedal/`, the track G CLI (`cli-spi-sd/bin/gea.mjs`), `GEA_TARGETS_ROOT` at
`targets-pedal-43b` (a detached worktree: the track G branch plus the fork's source-walk fix
`d107bfb`, which upstream main still lacks; without it any build root other than `.gea/build`
fails on reconfigure with ninja's "dependency cycle: gea-vite-bundle.js", exactly as on
2026-10-12; and the RGB hunk of the fork's `f65c525`, the `Display::flushOdometerRead` the
core contract declares and the pedal's soak task calls, without which the link fails; both
one-file fixes are worth their own small upstream PRs), `GEA_CHIPS_DIR` at `core-main/packages/chips`, the `GEA_*_DIR` overrides at
`tmp/counter-43b/node_modules/@geastack` (compiler 1.0.33, core 0.1.42, engine 0.1.17, host
0.1.17: the stack upstream targets now pins), `GEA_PROJECT_BUILD_ROOT` absolute at
`.gea/build-43b`. The kit's `build/pedalboard.bin` was copied to
`build/pedalboard-lafvin-before-43b.bin` first, since every alias writes the same file.

What the board changes for the pedal, before any measurement:

- The native USB-C port is the console and, in audio mode, the host port. The pedal's
  reference board (the AMOLED 2.06) has the same arrangement, so the firmware already treats
  the console as something that disappears: panics are recorded in RTC memory and reported on
  the next boot, and an audio boot is "a bounded window, not a destination": a return timer
  armed first thing brings the board back to maintenance whether or not the host, the engine
  or the UI came up. Maintenance mode is the Wi-Fi link, discovery and the HTTP API, with the
  console back on USB. Flashing a board that is in audio mode needs BOOT held through the
  reset.
- No footswitch until one is wired. Tap and hold come from the panel and the API. And the
  boot rule had to change with it: the return-to-maintenance timer exists only for an
  explicitly requested audio window, so a plain audio boot is permanent, and on the kit the
  way out was holding BOOT. A board without a footswitch now boots into maintenance unless
  audio was explicitly asked for (`main.cpp`, the boot decision); audio comes as the API's
  bounded windows (`effects-profile`, `effects-soak`, `AUDIO TRY`) and `AUDIO MODE`.
- `.nam` filenames longer than 8.3 depend on the pedal's own FatFS long-name setting, which is
  the pedal's sdkconfig, not the board's.

Plan for the night: flash, watch the first audio window on the console until the host takes
the port, wait for the return to maintenance, `amoled_remote.py discover` and `status`, then
`effects-profile`: each effect alone and the six-effect chain, with the RGB panel scanning
the whole time. That number against the kit's 87% is the decision for the son-in-law build.

### First boot of the pedal on the 4.3B (2026-10-16, 08:20)

Built on the third try (the two failures were the fork's own known upstream gaps: the source
walk's `.gea` pruning and the RGB binding's flush odometer, both now stacked on the throwaway
worktree `targets-pedal-43b/`), 3.33 MB, 21% of the 4 MB slot free. Flashed over the native
port. The boot log, in order:

- `no footswitch on this board: tap and hold come from the panel and the API`, then
  `maintenance is the default boot`: the new rule works. The effects arena (35,520 bytes) and
  64 KB of the NAM bank arena are lent to the maintenance heap.
- The remote API comes up on port 8080, the station associates in 4 s and has
  `192.168.1.122` by 6.5 s, WPA2-PSK, RSSI -49 (the compatibility-mode opt-out carried over
  from the kit). UDP discovery did not reach it from the Mac; `--host` works.
- `BLE discovery startup failed`: the pedal built with `ble=0` on this board (the app
  capabilities line), so no BLE controller. Not investigated yet; the Wi-Fi link is the one
  that matters.
- The CH422G comes up, then the panel does not: `lcd_rgb_panel_alloc_frame_buffers: no mem
  for bounce buffer`, `Gea bring-up failed; the UI will not start (the app's own tasks keep
  running)`. The internal heap at init is 13 + 5 + 21 + 32 KiB, about 71 KiB in four pieces,
  and the RGB binding's bounce buffers are two blocks of 800 x 20 x 2 bytes, 32 KB each, in
  DMA-capable internal RAM. The counter starter had the whole chip; the pedal's link-time
  arenas own most of it (`docs/MEMORY.md`, "Where the internal budget goes").

The binding has the knob for exactly this: `GEA_EMBEDDED_DISPLAY_RGB_BOUNCE` 0 makes the
GDMA scan the PSRAM framebuffer directly, no internal buffers, and, in the binding's own
words, none of the "standing ~30% CPU tax on the render core" the bounce copies cost; the
price is scanout underrun ("visible drift") when CPU PSRAM traffic starves the DMA. For a
NAM pedal that is the right side of the trade to try first: core 0 is where USB and stage A
live. Set as a board define in `package.json` for the 4.3B and rebuilt.

Unreachable after that boot, though: with the UI failed, the pedal associates, gets its
address by DHCP (so the link carries traffic both ways at 4 to 6.5 s) and then answers
nothing, not a ping right after `station ready`, not port 8080, with no disconnect in the
log and nothing else on the console. The Mac (192.168.1.73, wired) has the right ARP entry.
Hypothesis to test with the direct-scanout build: a pedal task that waits for the Gea runtime
that never came starves lwIP after the failed bring-up. If the panel comes up and the
network answers, that is the explanation; if the panel comes up and it still does not, the
network is the next problem.

### Second boot: the panel on the pedal (2026-10-16, 08:45)

With `GEA_EMBEDDED_DISPLAY_RGB_BOUNCE` 0 on the board block, the same boot now continues past
the expander: `RGB panel ready 800x480 pclk=16000000 bounce_rows=0`, `GT911 found at 0x5d`,
the Gea runtime bootstraps, and the pedal's UI runs on the 4.3B in maintenance mode: about
15 fps, 65 ms per frame with the display flush taking almost all of it (`disp=64.9`). The
binding also reports `strip-raster OFF (no internal SRAM)`: the pedal leaves it no internal
memory for that either, so flushes take the slow path. A UI at 15 fps is usable for a pedal;
the audio-mode cost of that flush traffic is the number still to measure.

Two things the pedal does differently from the counter starter, learned on the way:

- It disables Gea's device control (`GEA_EMBEDDED_DEVICE_CONTROL=0`), so no `GEADEV` over the
  USB port: no screenshots, taps or state over USB on the pedal. Those go over the pedal's
  own HTTP API in maintenance mode.
- The pedal's remote API is reachable only over Wi-Fi, and that is where the night stopped.

### Blocked: the Mac cannot reach the pedal, or anything else on the LAN

The pedal associates and gets 192.168.1.122 by DHCP on every boot, so its link carries traffic
both ways at least until then, and the Mac's ARP table holds its MAC. But from the Mac
(192.168.1.73, its one interface en0, Wi-Fi) nothing on 192.168.1.0/24 answers: not the pedal
(ICMP, TCP 8080, and even a UDP `sendto` fails with "No route to host"), not the gateway at
192.168.1.254 (no ICMP, nothing on 80 or 443), not two other hosts the ARP table knows, while
the internet works through that same gateway (GitHub answers). `networksetup` says en0 is not
associated with any network although it holds the address. On 2026-10-12 this Mac reached
the kit on the same SSID, so something on the Mac's side changed. Nothing to do about it from
the pedal, and nothing I could change on the Mac without you.

The likely cause, found after the user's hint: macOS 15's per-app "Local Network" privacy
permission. An app without it gets "No route to host" for every LAN address while internet
traffic passes, which is this exactly; command-line tools inherit the permission of the app
that launched them, here the app hosting the Claude Code session. Fix: System Settings,
Privacy and Security, Local Network, switch on that app (if it is not listed, run `ping
192.168.1.254` once in the app's own terminal to trigger the prompt). Then `amoled_remote.py
--host 192.168.1.122 status`. The alias `lcd43b` in the pedal's `.gea/boards.json` carries
that host. Not the Claude Code sandbox: the same probes fail with it disabled. Confirmed by
the user the same morning: `ping 192.168.1.122` fails from the shell and answers under `sudo`
(root is exempt from the per-app check), 160 to 280 ms round trips, the pedal's Wi-Fi power
save. The permission switch is the real fix; sudo is the workaround for a single command.

The measurement run (`effects-profile` with the panel scanning) is one command once the link
works; the pedal is left flashed with the direct-scanout image, in maintenance mode, UI up.

### Two more fork fixes upstream main lacks

Both found again tonight, both one-file, both on the fork's `lafvin-composed-display` branch
since 2026-10-12 and stacked on the throwaway worktree `targets-pedal-43b/` for the pedal
build: `d107bfb` (the source walk prunes `.gea`, without which any non-default build root
fails on reconfigure) and the RGB hunk of `f65c525` (the RGB binding answers
`Display::flushOdometerRead`, without which any app that reads the odometer fails to link).
Each is a small PR of its own; backlog tracks H and I.

### State of the pedal fork after the night (uncommitted, branch `lavfin-kit-notes`)

`boards/esp32-s3-waveshare-touch-lcd-4.3b.json` (new), `package.json` (partition table, board
block with the 800x480 defines, ratio 1, WPA3 opt-out, `GEA_EMBEDDED_DISPLAY_RGB_BOUNCE` 0,
two SDSPI components), `src/native/storage/sd_models.cpp` (SPI card branch),
`src/native/main/main.cpp` (footswitch from the board's launcher button; maintenance is the
default boot without one). `npm run check` and `npm test` pass. The kit's `build/pedalboard.bin`
is restored; the 4.3B image is `build/pedalboard-43b.bin`.

### A pedal bug the board exposed: `nan` in the status JSON (2026-10-16, morning)

The first `status` from the 4.3B (run under sudo) was unparseable: `"drift_ppm": nan`. The
audio-window result struct is `RTC_NOINIT_ATTR`, garbage after power-on until an audio window
writes it, and the status renderer prints its floats with `%.2f` regardless of the struct's
magic word (it does report `"valid": false` from that magic, but prints the fields anyway).
Garbage float bits are routinely NaN, printf writes `nan`, and that is not JSON. The kit never
showed it because its first boot was an audio window, which wrote the struct before anyone
asked; a board whose first boot is maintenance answers its very first status that way.
Fix in the fork, `remote_service.cpp`: when the magic is wrong at the maintenance-boot report,
zero the struct once; `valid` stays false and every field is 0. Independent of the board; one
of the small pedal PRs.
