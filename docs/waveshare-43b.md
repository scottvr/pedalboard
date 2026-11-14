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
`targets-pedal-43b` (since 2026-10-23 the `pedal-43b` integration branch, `docs/branching.md`; before that a detached worktree: the track G branch plus the fork's source-walk fix
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

### The footswitch decision, revisited with the user (2026-10-16, morning)

The overnight change inferred "no footswitch" from the board layer's launcher button being
absent and made maintenance the default boot in that case. Both parts were wrong in
principle, as the user pointed out: a pedal is a stomp box first, the footswitch is its
primary interface once a preset is chosen, and the boot default is an explicit upstream
design decision ("the same firmware builds for a bare module with no panel ... and the BOOT
button is the footswitch") that a fork should not change without discussing it.

What stays, because the 4.3B forces it: the footswitch pin is the board block's decision in
`package.json`. `COYOPEDAL_FOOTSWITCH_GPIO` names the pin, `COYOPEDAL_FOOTSWITCH_NONE` says
the board has none, and without either the board's launcher button is the footswitch, BOOT
on every reference board. A board with no launcher button and no setting fails to compile
with a message naming the two, so a pedal cannot lose its stomp switch by omission. The boot
default is upstream's again: audio, with the Setup screen's "Maintenance mode" control and
a footswitch hold as the ways back. The 4.3B block says `NONE` until a switch is wired.

Discussed and parked, not coded:

- The matrix. Audio is the right default whenever the pedal has a way back, a footswitch or
  a screen; the only stranded configuration is headless and switchless, which could be an
  explicit "API-only" build that boots into maintenance, is configured over the API, and is
  sent to audio with `audio-mode` until the next power-cycle. Plausible for a maker whose
  enclosure gives no access to BOOT. A question for the maintainer, not a fork change.
- An expander-input footswitch on the 4.3B's isolated DI0. Not viable as the chip is driven
  today: the CH422G switches direction for all eight IO pins at once, and with outputs
  enabled (backlight, both resets, the card-select) a read returns the driven levels, not
  the optocoupler's. Reading DI0 would float the panel reset and the card-select on every
  poll. One bench experiment may change that: latch EXIO0 high instead of low
  (`initialOutputs` 0x1f) and see whether a closed dry contact reads back low through the
  optocoupler's series resistor, which is presumably how the vendor's own demos read it.
  Needs a wired switch. Until then the 4.3B footswitch is a soldered GPIO (6 is free, if the
  module pad is reachable) or a second I2C expander on the I2C terminal.

### Third boot: upstream's audio default, and where the internal RAM goes (2026-10-16, 10:30)

With the boot default restored, the first boot goes to audio and tries to place the NAM
graph: every factory profile is rejected (`S3 runtime alloc failed rl8=0/30344 free=52952
largest=26624`, thirteen history rings of 2 to 5 KB unallocated), then `Audio could not
start; maintenance available for recovery`: the pedal falls back to maintenance by itself,
the panel, touch, card, Wi-Fi and API come up as before. So upstream already handles the
switchless failure path, and the fallback is the real safety net, not the boot default.

The shortfall is about 28 KB, and the link maps (`esp_idf_size --files` on both images) put
the 4.3B image 27,362 bytes of static internal RAM above the kit's (DIRAM 215,793 against
187,901; 125,967 left for the heap against 153,859). Where:

| Growth | Object | Why | Remedy |
| ---: | --- | --- | --- |
| 9,656 | `audio_runtime.cpp` (framework host) | the framework's audio task stack, static; compiled only because the board declares an audio chip, the ES8311 stopgap | track A removes the stopgap and this with it |
| 4,977 | the generated UI object | the shipped `gea_ui_state_external.lf` moves "the display, runtime and tree_render objects of the app's main component" by name; the new compiler emits one hashed object the fragment does not catch | a fragment or compiler question for upstream |
| 4,363 | `gt911.cpp` | a static task stack and controller object; the FT3168 binding honours `GEA_EMBEDDED_TOUCH_TASK_STACK_EXTERNAL`, this one does not | a small targets PR: the GT911 binding takes the same switch |
| 3,648 | `canvas.cpp` (engine) | engine 0.1.17 against the kit's 0.1.10 | none; version cost |
| 3,886 | `rgb_panel.cpp`, `esp_lcd_panel_rgb.c`, `gdma_link.c`, SPI | the RGB path's driver state | small and legitimate |

The RGB panel's framebuffers are in PSRAM and are not in this list. Recovering the first
three rows (19 KB) plus fragmentation relief may be enough; the stopgap's 9.7 KB alone is
the largest single item and is exactly what track A was for. The pedal fork's three commits
of the morning: the status NaN fix, the footswitch as a board-block setting, and the 4.3B
board support, each with its own message.

### Controls beyond touch: the pin budget, read from the schematic (2026-10-16, evening)

The question was how many physical controls the board can take (a stomp switch or two, a
couple of knobs) and whether any of the feature pins can be jumpered back to GPIO. The
schematic (`docs/waveshare-43b-schematic.pdf`, from the wiki) answers both.

The module has 33 usable GPIOs and the board commits 32: the panel takes 20, the card 3,
USB 2, I2C 2, the touch interrupt 1, and the RS485 and CAN transceivers 2 each. The
remaining one, GPIO 6, is the RTC's interrupt line, and no GPIO reaches a header. The only
configuration on the board is a DIP switch for the 120-ohm CAN and RS485 terminators, a
solder jumper choosing 3.3 V or 5 V for the I2C header, and unpopulated pads for the
strapping-pin resistors; the four 0-ohm links are on the card lines. The transceivers
(SP3485EN for RS485, TJA1051 for CAN) are wired straight to the module, so nothing frees a
pin without soldering. What each of the five non-panel pins allows:

| GPIO | On the board | Usable as | Why |
| --- | --- | --- | --- |
| 43 | RS485 receive: the SP3485's RO through R64 (4.7 K) | input, switch to ground | RO idles high in receive mode and acts as a weak pull-up through the 4.7 K; nothing to remove |
| 15 | CAN transmit: straight into the TJA1051's TXD | input, switch to ground | TXD is high impedance with an internal pull-up; a low only makes the unconnected bus dominant until the chip's timeout |
| 6 | the PCF85063's INT, open drain | input, or ADC1 channel 5 for one pot | the RTC never asserts it unless firmware enables an alarm, which the pedal does not |
| 44 | RS485 transmit: a transistor base through R68 (100 ohms), R67 4.7 K pull-up | output only | the base junction clamps the net near 0.75 V, so an input reads low until R68 is removed |
| 16 | CAN receive: driven push-pull by the TJA1051's RXD | nothing | driven even in standby; reclaiming it means lifting the pin |

So three clean inputs without a second board: 43, 15 and 6. One encoder on 43 and 15
plus a stomp switch on 6, or two switches and one pot on 6; the two isolated DI lines come
on top if the expander read works out (above). GPIO 15 and 16 are ADC2, unusable with
Wi-Fi up, so GPIO 6 is the only analog input. GPIO 43 and 44 are UART0: the ROM bootloader's
boot messages go out of 43 into the RS485 receiver through the 4.7 K, harmlessly. Note the
board's net names are from the bus's point of view: GPIO 43 (the S3's U0TXD) receives, GPIO
44 (U0RXD) transmits, so the vendor's RS485 demo must route the UART through the matrix.

Solder points, all on the bottom side or the module edge: the module's castellations
(1.27 mm pitch; IO6, IO15, IO16 on one edge, IO43, IO44 on the other), or a component pad:
R64 for GPIO 43, the TJA1051's pin 1 for GPIO 15, the PCF85063's pin 4 for GPIO 6. The two
chips are SO-8; the resistors are unmarked for size, probably 0402.

A firmware dependency first: those five pins are exactly the ES8311 stopgap's fake I2S
lines in the pedal's board block, chosen because nothing else used them. Track A (gate the
audio binding on a composed board's audio chip) has to land, or the stopgap has to move,
before a reclaimed pin can be configured as a GPIO; and there is nowhere for the stopgap to
move to. Track A was already first in line for the RAM shortfall.

Knobs: on a preset pedal an encoder beats a pot, because a pot is absolute and points at the
wrong value after a preset recall while the panel already shows the number. Beyond the three
reclaimed pins, controls go on the I2C header: an MCP23017 polled at about 1 kHz for
encoders and buttons (plus an I2C ADC if a pot is still wanted), or a small MCU on the leash
presenting one register map, which also carries over to the P4 project. Either way the pedal
needs a new input path: today its only physical control is the one footswitch's tap and
hold. The isolated DO0/DO1 (450 mA open drain) can drive an engaged LED on a leash.

Enclosure shape that follows: the 4.3B face up as the display unit with its battery, the
stompable parts in a separate box on a short cable carrying the I2C lines and the isolated
I/O; keep the I2C leg under about a metre at the bus's current speed.

### Track A on the pedal (2026-10-16, evening)

The track turned out smaller than planned: the base target already had a no-audio path
(`audio_runtime_stub.cpp`, `GEA_EMBEDDED_AUDIO_UNUSED=1`) for apps that never import audio,
chosen from the app analysis; what was missing was the board having a say. The CLI now sets
the app's audio capability to off when a composed definition has no `chips.audio`
(`customTargetDeclaresAudio` in `custom-target.mjs`, called in `prepareEsp32Build` before
the capability reaches the `-D` cache and the environment; `target.cmake` also gains
`GEA_CUSTOM_TARGET_HAS_AUDIO`), and the base target's CMake forces the same from that flag
before it reports the capabilities, for a direct `idf.py` build or an older CLI. One test
in each repository; the CLI's board, build-config and esp32 suites pass (60 tests).
Branches `composed-no-audio-chip` in `cli-track-a/` and `targets-track-a/` (cli 96c9928, targets 5a9ce5a, committed 2026-10-23).

The 4.3B definition lost its ES8311 block. The pedal needed one fix: `internal_speaker.cpp`
declared its worker handle outside the `GEA_BOARD_HAS_SPEAKER` guard, an unused-variable
warning in the no-speaker build; guarded. Built, flashed over USB, boot log captured over
the USB-Serial/JTAG port with a reset from the Mac (`capture_boot.py`, pyserial, the esptool
DTR/RTS sequence):

| | before (morning image) | track A |
| --- | ---: | ---: |
| DIRAM used (link map) | 215,793 | 205,801 |
| image | 3,329,232 | 3,270,544 |
| internal heap at init | 13 + 5 + 21 + 32 KiB | 22 + 5 + 21 + 32 KiB |
| `before NAM load` free / largest | 52,952 / 26,624 | 62,416 / 31,744 |
| history rings unallocated | 13 | 9 (27,888 bytes) |

So the audio runtime's 9,656-byte static stack and the codec objects are gone as the map
predicted, and the graph still does not place: the plan wants 30,344 bytes in one piece
plus the rings, and the largest piece is 31,744. The pedal falls back to maintenance as
before; panel, touch, Wi-Fi and the API come up. The per-object difference against the
kit's map, with track A in: 17,356 bytes, of which the generated UI object 4,977, `gt911`
4,363, `canvas` (engine 0.1.17 against 0.1.10) 3,648, the RGB path 3,886, `usb_audio` 787.

Tracks J and K address the first two:

- J: the GT911 binding takes `GEA_EMBEDDED_TOUCH_TASK_STACK_EXTERNAL` exactly as the FT3168
  binding does (object in PSRAM, heap task stack there, static members compiled out; the INT
  ISR is installed without `ESP_INTR_FLAG_IRAM`, so touching the PSRAM object from it is
  fine). Branch `gt911-external-task-stack` in `targets-track-j/`.
- K: the shipped `gea_ui_state_external.lf` named `libmain.a` objects from when the app's
  generated code compiled into main; the compiler now emits one content-hashed object into
  `libgea_active_geatsc.a` (the kit's older compiler had none of it in DIRAM at all). A
  fourth mapping sends that archive's `.bss` to external RAM; ldgen only existence-checks
  entries more specific than an archive, so a build without the archive is unaffected.
  Branch `ui-state-external-app-archive` in `targets-track-k/`.

Both are stacked on `targets-pedal-43b/` with A and built into `.gea/build-43b`
(`build-43b-trackAJK.log`), not flashed: the Mac's system volume filled up during the
session (364 MB free of 466 GB, swap at 4.4 of 5 GB), ldgen and then the final link spent
tens of minutes in disk wait. After the disk is freed: flash, capture the boot, and read
`before NAM load` again. Expected: another 9.3 KB static, taking the image to about 8 KB
over the kit, the rest being the engine version and the RGB driver. If the graph still
misses then, the lever is the pedal's own placement (`coyopedal/docs/MEMORY.md`) rather than
the board.

Images: `build/pedalboard-43b.bin` is the track A image, `pedalboard-43b-before-trackA.bin`
the morning's; the kit's `build/pedalboard.bin` is restored.

Tried and reverted: removing the stopgap from the two LAFVIN definitions. The kit's bench
build is `npx gea build --board lafvin` on the stock packages, which lack track A, and a
codec-less definition does not build there. The kit waits for the release.

### The pedal's audio boot places on the 4.3B (2026-10-16, 22:05)

The stacked image (A + J + K) linked at 196,713 bytes of DIRAM (145,047 left; 8,812 over
the kit, which is the engine version and the RGB driver), 3,266,128 bytes. Flashed over USB
and reset with the capture script: `before NAM load: internal free=67404 largest=31744`,
the history rings all place (`NAM bank arena returned 5680 unused bytes`), `profile
volum-herbert-1-v30 loaded, 48616 bytes`, `factory preset A2-Full model loaded and calibrated
in 3873 ms`, the compact reverb takes 38,884 bytes internal with 16,432 left, `effects ready`,
and then `starting USB audio host for the attached UAC2 interface; internal free=12332
largest=3840`. The next thing the Mac saw was the USB-Serial/JTAG device vanish: the pedal
took the port for the host, which is the audio boot working on this board for the first
time. GT911 and the generated UI object are at 2,631 and 0 bytes of DIRAM in that map.

Where the bench stands: the pedal is in audio mode on the 4.3B, radios off, console gone.
The way back is the Setup screen's "Maintenance mode" control on the panel (no footswitch,
no BOOT hold on this board); the measurement (`effects-profile` over the API with the panel
scanning) then needs the Mac to reach the pedal on the LAN, which still needs the Local
Network permission or sudo. Both are the user's hands. The Mac's system disk is also full
(364 MB free at one point, 1.4 GB later), which turned a two-minute link into twenty.

| image | DIRAM | internal free before NAM load | largest | result |
| --- | ---: | ---: | ---: | --- |
| morning (stopgap) | 215,793 | 52,952 | 26,624 | 13 rings unallocated |
| track A | 205,801 | 62,416 | 31,744 | 9 rings unallocated |
| A + J + K | 196,713 | 67,404 | 31,744 | graph placed, audio host started |
| kit (LAFVIN, for reference) | 187,901 | | | audio boot works |

### Track A, second shape: the codec is not the policy (2026-10-16, 23:00)

On the panel the user saw the UI scroll horizontally and stutter, wrapping at one point, and
the Setup button ignore touch; taps anywhere did nothing. Both are new with the stacked image
and both trace to the same thing: the first shape of track A turned the app's audio
capability off for a codec-less board, and the base target uses
`GEA_EMBEDDED_APP_USES_AUDIO` for more than the codec. In `display.cpp` the parallel render
worker blocks on a notification between jobs when the app uses audio and spin-waits up to
4 ms otherwise; the join on the main core likewise. So the pedal was built as a non-audio
app: both cores spin around every frame, on a pedal whose DSP already has 87% of both. The
pedal's own priorities (runtime 17, frame 18, touch 17) were unchanged, which is why the
first read of the log looked fine. The scanout drift is the same load: the RGB DMA reads
the framebuffer straight from PSRAM (bounce buffers off, for lack of internal RAM) and
underruns when the cores saturate the bus.

Second shape: the CLI only emits `GEA_CUSTOM_TARGET_HAS_AUDIO` in `target.cmake`, and the
base target sets `GEA_EMBEDDED_BOARD_HAS_CODEC` from it. The codec sources (ES8311, the
audio runtime, `esp_driver_i2s`, `esp_codec_dev`, `GEA_BOARD_HAS_SPEAKER=1`) need the
capability and the codec; the stub build of an audio app keeps
`GEA_EMBEDDED_APP_USES_AUDIO=1` beside `GEA_EMBEDDED_AUDIO_UNUSED=1`. The CLI's capability
override and its helper are gone; the tests follow. Rebuilt with the 4.3B block at
`cssDevicePixelRatio` 1.5 as asked (logical 533x320; touch scales with it, since the
hit areas are the same logical boxes).

Also learned the hard way: the pedal's audio boot takes the USB-C port for the host, and
if that port is on the Mac the Mac's USB controller stalls (keyboard dead, display blank)
until the cable is pulled. Flash, unplug, then power the board from elsewhere. To flash a
board that is in audio mode, hold BOOT while plugging it in: the ROM's download mode is a
strapping read at reset and works on this board even though GPIO 0 is a panel line.

### Scanout drift: VSYNC restart, the clock the panel wants, 2x (2026-10-17, morning)

With the second shape of track A flashed, the picture still crept to the right on every tap
and wrapped, and touch was "unpredictable": the hit boxes had not moved, the picture had.
The scanout reads the framebuffer straight from PSRAM (no internal RAM for bounce buffers),
code and rodata execute from PSRAM too (`CONFIG_SPIRAM_XIP_FROM_PSRAM`), and a render's
PSRAM burst starves the DMA; the pixel clock keeps going and the frame stays displaced.

Three changes, two of which survived:

- `CONFIG_LCD_RGB_RESTART_IN_VSYNC=y` in the pedal's `sdkconfig.defaults`: the driver
  restarts the transfer at each VSYNC, so an underrun is a one-frame tear instead of a
  permanent shift. Kept. Result on the panel: a tap causes visible horizontal wiggle that
  settles in a few seconds; several taps in quick succession, especially during the
  wiggle, build it up to a hard shake by about the third, then it settles again and the UI
  keeps working. Touch answers where things are drawn.
- `pclkHz` 12 MHz instead of 16: the driver reports ready, the UI renders at 15 fps, and
  the panel shows solid white. The panel does not lock below its rated clock. Reverted;
  the pedal's definition says why.
- `cssDevicePixelRatio` 2 (400x240 logical): "a fair size", the user's words. Kept.

Where the remaining wiggle can go, in order of plausibility: a dirty-rectangle flush
instead of the full 768 KB canvas-to-framebuffer copy per frame (`disp=64.9` ms of the
65 ms frame is that copy); the binding's single-framebuffer mode (draw into the scanout
buffer, no copy, tearing instead of bandwidth); bounce buffers if 64 KB of internal RAM can
be found (the graph leaves 16 KB); PSRAM at 120 MHz (experimental on the S3, flash must
follow). The first is a Gea question, the rest are board-block switches.

Bench technique that made this session possible: a board in audio mode has no console and
no safe USB connection to the Mac, so to see one boot the next boot is flagged from the
Mac. An NVS image with namespace `coyopedal_mode`, key `maintenance` u8 1 (generated with
IDF's `nvs_partition_gen.py` from a three-line CSV, written at 0x9000 with esptool) makes
the next boot a maintenance boot; the flag is one-shot, the boot after it is audio again.
The capture scripts (`capture_boot.py`, `capture_after_reset.py`) live in
`tmp/session-scratch/`; esptool is driven directly with `--after no-reset` so a flashed
board stays in its bootloader until unplugged, and never becomes a host on the Mac's port.
Oddity not explained: from the ROM bootloader state, every reset issued over the
USB-Serial/JTAG lines landed in download mode again (`boot:0x0`), while the same sequence
from a running app boots normally; the board's own RESET button boots normally.

### The board's death (2026-10-19, after midnight)

**Resolved, not dead (recorded 2026-11-14):** the fault was a bad USB cable on the hub. With
the cable replaced the 4.3B runs normally; the "death" below and the power-circuit reading
were wrong. Kept for the record of how one symptom was misread twice. The hardware checks it
paused are open again.

**Addendum 2026-10-23:** the symptom below, rapid LED and panel flashing at power-on, was
reproduced on the LAFVIN dev board from one port of the USB hub, bare and in the carrier, and
vanished on another port. That is a power-delivery fault on the hub side, not the board. The
4.3B was never tried on another port after it "died", so retest it on a known-good hub port
and on a direct port before concluding anything. The USB-plus-VIN-plus-charger wiring may
still have hurt it, but the evidence no longer says so.

The 4.3B was being wired for VIN and a battery charger with the USB cable still plugged in.
A click, not a capacitor, and since then the board flashes its LED and panel rapidly at
power-on, with the panel detached as well, and no button combination at power-on changes it.
Read as a power-circuit part gone; to fix later or salvage. The panel (800x480 RGB, GT911,
40-pin FPC) came off working and is kept for a replacement board.

What it pauses: every hardware check in the 4.3B sprint item, the footswitch wiring on DI0,
the effects-profile run with the panel scanning. What it does not pause: the fork commits
for tracks A, J and K and their PRs, which are host work. The display work moves to the
generic S3 devkits with bare SPI panels (`docs/displays.md`).
