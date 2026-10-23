# Sprint and backlog

The working list for the whole project. `docs/` is the knowledge log (what we learned and
why); this file is what we do next. Code changes land in the four repositories beside this
file; the pedal fork's branch is `lavfin-kit-notes`.

## Cadence

- A sprint is one hardware session. Before it: read "Status" in `README.md`, then "Current
  sprint" here. After it: move finished items to "Done", write what was learned into the
  topic file under `docs/`, pull the next items up from the backlog, commit here and in the
  repositories that changed.
- Host-side work (tests, parsers, docs, upstream branches) can happen any time; hardware items
  wait for the bench.
- Work that lives outside this repo (the Geastack forks) is a **track** in the table below:
  one row per upstream change, with its fork branch, what it has run on, and its PR. That
  table is the only place that state is kept.
- Upstream-bound changes go up one per branch. The working branches (`lavfin-kit-notes` in
  the pedal, `lafvin-composed-display` in the Geastack forks) take every commit first; when a
  change is ready to send, it is cut as its own branch off that upstream's main by
  cherry-pick and opened as its own PR. A change that alters a default or turns an undefined
  case into an error is written on its own feature branch from the start and sent with the
  design argument in the message, after asking upstream.
- A task handed to a subagent gets a **brief** first: goal, the files it may touch, how it is
  tested, and what "done" looks like. The brief lives under the track or sprint item it serves;
  the agent reads the topic file under `docs/` for background and writes findings back there.
- Build, from `coyopedal/`: `IDF_TOOLS_PATH=/Volumes/idf6/.espressif-idf6 npx gea build --board lafvin`.
  Flash a built image without rebuilding: `npx gea flash --board lafvin --no-build --monitor`.
  Never run two builds against one build directory; a flash reads from it too. Run `npm test`
  and `npm run check` after source changes. The display variant builds against the forks:
  `docs/build-environment.md`.

## Current sprint: the carrier's display, and the Wi-Fi tail

Goal: the pedal draws on the kit's 2.8" panel and takes touch, through composed-target
support contributed upstream; meanwhile the maintenance link works on the main network.

Wi-Fi tail (one bench visit):

1. Done 2026-10-12: the main-network join (see Done). External antennas arrive 2026-10-13;
   the SMA path makes the carrier socket irrelevant to the radio.
2. `effects-profile` over the API: per-effect cost on this board (both cores sit at 87%).
3. Cable arrived 2026-10-13 (TRS 1/4" to 1/8"): loopback glitch count and the drift experiment
   (`docs/audio/momix.md` "MOMIX drift", `docs/audio/usb-audio.md` "Per-device timing"). Keep the input below
   full scale. The counter exists since 2026-10-13: `AUDIO TRY 300 LOOPBACK` (pedal commit
   `7f3cbcb`), host-tested; it also measures the round-trip latency and the drift. First
   hardware run is this item.

The 4.3B as a pedal home (decided 2026-10-16, after the gift ran):

8. Track G, SPI microSD, first: done 2026-10-16 (see Done). The pedal on the 4.3B (fork
   commits `42e125f`, `d394871`, `9f6d5b2`): boots with upstream's audio default, the NAM
   graph misses internal RAM by about 28 KB and the pedal falls back to maintenance; panel,
   touch, card, Wi-Fi and API up, UI at 15 fps. Evening 2026-10-16: track A built and flashed,
   9,992 bytes back, the graph still misses by 9 rings (27.9 KB; `docs/waveshare-43b.md`,
   "Track A on the pedal"). Tracks J and K (9.3 KB more) are built into
   `.gea/build-43b`, flashed at 22:05: the graph places (free 67,404 before NAM load), the
   model loads and calibrates, the USB host starts and takes the port. Morning 2026-10-17:
   the second shape of track A (the app keeps its audio policy define) restored touch and
   blocking render waits; VSYNC restart turns the scanout drift into a settling wiggle;
   2x scale; 12 MHz pclk shows a white panel (reverted). Touch works at 2x. Remaining:
   the per-render wiggle (`docs/waveshare-43b.md`, "Scanout drift"). Next, by hand: Setup > Maintenance mode on the panel, then
   `effects-profile` over the API with the panel scanning, which needs the Mac to reach the
   pedal (Local Network permission for the hosting app, or sudo) and a system disk with
   room (it was full on 2026-10-16 evening). The fork commits for A, J, K and the pedal
   (speaker guard, 4.3B definition without the stopgap: `e782313`) landed 2026-10-23; the
   three PRs are left.
   **Paused 2026-10-19:** the 4.3B board died on the bench (USB still plugged in while VIN
   and a battery charger were wired; now flashes its LED and panel rapidly at power-on, a
   power-circuit part). The panel came off working and is kept. The host-side part of item 8
   (fork commits for A, J, K, the PRs) does not need the board and stays; the hardware checks
   wait for a replacement 4.3B. See `docs/waveshare-43b.md`, "The board's death".

Bench displays (ordered 2026-10-19; the ST7796 modules arrived 2026-10-21, the two Waveshare
DSI panels 2026-10-22; the inventory is `docs/displays.md`, "Displays on hand"):

9. Two XIITIA 3.5" ST7796 SPI modules (320x480, 8-pin, no touch, 3.3 V; one in hand 2026-10-21,
   the second unaccounted for) for the generic S3
   devkits: the display-only pedal on a bare S3, the composer's SPI adapter (track B's shape,
   ST7796 beside ST7789), and the external foot-controller build: real stomp switches and an
   encoder on GPIO first, an expander later. Footswitches and enclosures also ordered.
10. Waveshare 5-DSI-TOUCH-A (720x1280, HX8394, GT911-family touch, needs its own 5 V lead) for
    the two P4 boards: the panel for Gea's first P4 run, a new DSI controller for the targets.
    On hand since 2026-10-22, with the 4.3inch DSI LCD (touch) bought with the Pi case, which
    is a bridge-chip panel, not a P4 panel; it waits until the 5-inch proves the P4 DSI path.
11. The Waveshare ESP32-S3-Touch-LCD-3.49 (172x640 AXS15231B QSPI, ES8311, SDMMC card),
    assessed 2026-10-21 (`docs/displays.md`). Upstream landed a hand-written V2 target the
    same day (`b9db1ab`, targets issue #7), so there is no demo-app PR to send. Left: a V1
    pin variant if anyone has a V1 (backlight 8, reset 21, expander INT 42); a composed
    `axs15231b` display and touch pair only if the composer route is wanted; and the pedal
    UI's 205-row minimum against the 172-row landscape, which is coyopedal work. No board
    on hand; nothing scheduled.

Display (tracks B and C below, then the bench):

4. Hardware mod. Pins 0, 19 and 20 were lifted before the 2026-10-10 first-light runs (the
   board has sat in the carrier with the native port hosting the MOMIX and BOOT as the
   footswitch since). Left: two signal jumpers with the camera ribbon unplugged, the panel's
   MOSI pad to GPIO 16 and its D/C pad to GPIO 17, the pins the display definition names.
   SCK 21 and CS 47 stay as wired; GPIO 3, 46 and 15 stay with the ES8311 stopgap. The
   carrier routes no backlight or reset GPIO to the panel: BL is always on, RST follows EN.
5. Done 2026-10-12 (host side): `boards/esp32-s3-lafvin-multimedia-2.8-display.json` with
   `chips.display` (spi, st7789, 240x320, BGR, 40 MHz) and `chips.touch` (ft6336, polled), its
   `package.json` block (`cssDevicePixelRatio` 1, logical 320x240) and partition table, built
   against the forks through the CLI's package-path overrides (`docs/build-environment.md`).
   First fork build done the same day: it links (`docs/display.md`, "First fork build"); the
   image is `images/lafvin-display-20261012-fa703b1-first-link`.
6. First light on the panel: orientation, colour order, inversion, then touch. Raise the SPI
   clock only after it is right at 40 MHz.
7. Write results into `docs/display.md`; PRs go up only after the panel has run.

## Upstream tracks

Repositories: github.com/geastack/cli, geastack/targets, geastack/core (packages/chips). All
GPL-3.0, releases most days, no CONTRIBUTING file, and the one author is `dashersw`, who
also wrote coyopedal: one upstream conversation covers all four repositories, and the Gea
PRs go first because the pedal's board definition depends on them. State as of 2026-10-12.

| Track | Change                                                                                                                                                                                                                                         | Repos               | Fork branch | Ran on hardware | PR  |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ----------- | --------------- | --- |
| A     | Gate the ES8311 binding on a composed board's audio chip: the CLI turns the app's audio capability off when the definition has no `chips.audio` (`customTargetDeclaresAudio`, `GEA_CUSTOM_TARGET_HAS_AUDIO` in target.cmake) and the base target guards the same before choosing `audio_runtime_stub.cpp`; tests in both. The s3-devkit `GEA_BOARD_HAS_POWER` line is a coyopedal item, not part of this | cli, targets        | topic `composed-no-audio-chip`: cli 8c4322a (`cli-track-a/`), targets 0f10f86 (`targets-track-a/`), on upstream main of 2026-10-23; merged into `pedal-43b` | yes, 2026-10-16: the 4.3B pedal builds without the stopgap and boots; 9,992 bytes of DIRAM back, NAM heap free 52,952 to 62,416, largest block 26,624 to 31,744; the graph still misses (9 rings, 27.9 KB) | not yet |
| B     | SPI panel for composed targets: composer accepts `interface: "spi"` (st7789 first), emits the ST7789 display struct and defines; base CMake includes the sticks3 pipeline; pipeline gains colour order, inversion and optional backlight/reset | cli, targets, chips | `lafvin-composed-display`: cli 5aea1d9, targets c84bff1 f65c525 d107bfb, core 14f08ad | builds, not flashed |     |
| C     | FT6336 touch adapter in the chips catalog; the binding gains the Touchscreen surface (`ft6336_touchscreen.cpp`), viewport mapping and the audio task-priority rule; the base's touch gate already admits any non-FT3168 driver                | chips, targets      | `lafvin-composed-display`: targets ca3372d, core 14f08ad | builds, not flashed |     |
| D     | Codec-less I2S DAC binding for the PCM5100 (I2S half of the ES8311 binding without the codec-dev calls); only if the kit's speakers become the monitor path                                                                                    | targets, chips      | not started | no              |     |
| E     | Ask whether the LAFVIN target belongs in `@geastack/targets` once B and C are in                                                                                                                                                               | targets             |             |                 |     |
| F     | Waveshare ESP32-S3-Touch-LCD-4.3B as a composed board: the 7-inch definition's panel electronics with the B's notes (RS485 on UART0, CAN, isolated I/O, RTC, charger), a `build-config.json` entry and a board page; a small gift PR, asked about by someone on his side (`docs/waveshare-43b.md`) | targets             | `waveshare-touch-lcd-4.3b` (rebased on upstream `9546973`) | yes, 2026-10-15: panel, touch by hand, counter runs | [targets#5](https://github.com/geastack/targets/pull/5), opened 2026-10-16 |
| G     | SPI microSD for composed boards: the composer takes `storage.microSD.interface: "spi"` (MOSI, MISO, SCK, chip-select on a GPIO or an expander line), the base's card mount gains the SDSPI path, declared on the 4.3B and the 7-inch (same wiring). Second gift; the pedal needs it to boot on the 4.3B (`docs/waveshare-43b.md`) | cli, targets        | topic `composed-spi-microsd`: cli 4862571 (`cli-spi-sd/`), targets 17c0d18 (`targets-spi-sd/`, stacked on the gift branch 24a238f in `targets-4.3b/`); rebased onto upstream main and force-pushed to the fork 2026-10-23, PRs mergeable | yes, 2026-10-16: card mounts over SPI2 with the select on EXIO4, push and list verified | [cli#7](https://github.com/geastack/cli/pull/7) and [targets#6](https://github.com/geastack/targets/pull/6) (sits on #5), opened 2026-10-16 |
| H     | Source walk prunes the CLI's `.gea` state directory (fork `d107bfb`); without it any build root other than `.gea/build` fails on reconfigure with a ninja dependency cycle | targets             | topic `source-walk-prune-gea-state`: targets 4391f83 (`targets-track-h/`), cut 2026-10-23 from the bench chain's commit; also on `lafvin-composed-display` as `d107bfb` | yes, every pedal build since 2026-10-12 | not yet |
| I     | RGB panel binding answers `Display::flushOdometerRead`, which core's display contract declares (RGB hunk of fork `f65c525`); without it an app that reads the odometer fails to link | targets             | topic `rgb-flush-odometer-read`: targets df7e404 (`targets-track-i/`), cut 2026-10-23 with a full message; also inside `f65c525` on `lafvin-composed-display` | yes, 2026-10-16 on the 4.3B | not yet |
| J     | GT911 binding honours `GEA_EMBEDDED_TOUCH_TASK_STACK_EXTERNAL` like the FT3168 binding: controller in PSRAM, heap task stack there, static members compiled out (4.4 KB of internal RAM on the 4.3B pedal); test covers both bindings | targets             | topic `gt911-external-task-stack`: targets 7504bc5 (`targets-track-j/`), on upstream main of 2026-10-23; merged into `pedal-43b` | yes, 2026-10-16 22:05: with A and K stacked, the 4.3B pedal's audio boot places the graph and starts the USB host (`docs/waveshare-43b.md`, "The pedal's audio boot places") | not yet |
| K     | `gea_ui_state_external.lf` also maps `libgea_active_geatsc.a` (the compiler's one hashed app object, 4,977 bytes of DIRAM on the 4.3B pedal, 4,269 of it .bss) to external RAM; ldgen does not existence-check an archive-level wildcard, so apps without the archive are unaffected | targets             | **Superseded 2026-10-23**: upstream `dfeb417` adds the same `libgea_active_geatsc.a` mapping to the fragment; branch and worktree dropped (old tip kept as tag `pre-rebase-ui-state-external-app-archive`) | yes, same boot as J | none needed |

Branch model: `docs/branching.md` (adopted 2026-10-23). Each fork's `main` mirrors upstream;
topic branches above are the PRs; integration branches build the pedal: `pedal-43b` (cli and
targets, worktrees `cli-pedal-43b/` and `targets-pedal-43b/`: upstream main of 2026-10-23
plus `--no-ff` merges of the gift board, G, H, I, A and J; cli 237ab6d, targets 0a72f6e)
and `lafvin-composed-display` (the three main clones: B, C, H, I developed on it before the
model existed, so it is both topic and integration until B and C are cut as PRs). Every
topic was rebased onto that day's upstream main; K turned out to be upstream already. The
rebuilt `pedal-43b` has not been built yet (no 4.3B to run it on): the next build should
also move `GEA_CHIPS_DIR` from `core-main/` (upstream main of 2026-10-16) to core's `main`,
since the rebased targets pin a newer core. The pre-rebase tips are kept as `pre-rebase-*`
tags in cli and targets until that build passes. Build commands in
`docs/build-environment.md`. Design: `docs/display.md`.

## Backlog

### Pedal firmware

- UAC1 streaming fixes that the loopback test exposes (expected: rate adaptation against the
  async capture, see "MOMIX drift" and "Per-device timing" in NOTES).
- Loopback probe follow-ups once it has run on hardware: tune `glitch_ratio` and the hold-off
  against a real return; decide whether the MOMIX sheet's latency should subtract the pedal's
  own ring depth; a `loopback` verb in the remote tool that runs the window and prints the
  summary.
- Quirk table keyed by VID:PID; iRig HD 2 profile retirement (plan in `docs/audio/usb-audio.md`; needs the author's
  HD 2 dump and a switch to route the HD 2 through the generic path).
- `MOMIX BACKUP` / `MOMIX FLASH` maintenance commands (design in `docs/audio/momix.md`, "Planned: flashing the
  MOMIX from the pedal"). Prerequisite: the manual breakout + jl-uboot-tool route proven once.
- Hide the speaker control when the board's codec init fails (verify the binding already does).
- Remove the ES8311 stopgap from both LAFVIN definitions once track A ships in released
  `@geastack/cli` and `targets`: the kit's bench build uses the stock packages, and without
  track A a codec-less definition does not build there (tried and reverted 2026-10-16).
- `tools/audio-devices-table.py`: read the front matter of every `docs/audio/devices/*.md`
  sheet and render the "Interfaces assessed" table in `docs/audio/usb-audio.md` from it, so the
  sheets are the single source. Host-side, any time; worth it once a second sheet exists.
- Ask upstream to rename `tools/esp32/amoled_remote.py`: its messages already say "CoyoPedal"
  on any board (fork commit `7b81d9c`) and its discovery match was never board-specific; only
  the file name lags. Low priority, easy ask alongside the UAC1 PR.
- Browser UI for maintenance mode (`docs/web-ui.md`), own feature branch, developed against a
  headless S3 and inherited by the panel boards: a page served by the existing httpd, in the
  pedal's own stylesheets and font, over the existing API. Design note to the maintainer
  first; after the 4.3B measurement.
- Runtime Wi-Fi provisioning over Improv Serial (`docs/wifi.md`), own branch:
  credentials to NVS, compiled header as fallback, the API token stays compiled until the
  device can generate and reveal one.

### Hardware

- MOMIX manual flash: USB-C breakout, D+/D- on two GPIOs of a spare dev board for the 0x16EF
  key wiggle, VBUS and ground from the Mac, backup with jl-uboot-tool, then Rob's
  `flash/jl_692x.bin`. Only needed if the MOMIX headphone jack becomes the pedal's output.
- Choose the pedal's audio output on the kit: the PCM5100 module (track D) or an external DAC.
- Kit audio module (PCM5100 DAC + PAM8403 amp on GPIO 42, 14, 41): decided 2026-10-13 to
  leave it plugged in and ignore it until after the display's first light. It is cruft for the
  USB-in, USB-out pedal, costs no pin anyone wants, and is the only hardware track D could
  drive. If a monitor jack is wanted: a PCM5102A breakout with a 3.5 mm jack on the same three
  I2S lines (`docs/kit.md`, "The audio module").
- Tracks F and G are open as PRs (table above); when #5 merges, rebase #6 onto main so it
  shows one commit. Fold review feedback back into `docs/waveshare-43b.md`.
- Two Waveshare ESP32-P4 boards arrived 2026-10-13: an ESP32-P4-WIFI6-POE-ETH (ES8311 codec,
  Ethernet with PoE, C6 with an IPEX antenna) and an ESP32-P4-Module-DEV-KIT (four USB-A ports,
  Ethernet). Both panel-less, both in `docs/p4.md`. They belong to the next project, below.

### Next project: NAM on the ESP32-P4 (`docs/p4.md`)

Starts after the kit's display and the gift PR. Before any code, ask the maintainer the
courtesy question written in `docs/p4.md` (he has P4 work he is keeping closed). First
milestone: a Gea P4 target's first real run on a board on hand, with the C6 Wi-Fi link up.
The pedal-port board is the POE-ETH on hand: its ES8311 is the pedal's codec, so the headless
boot needs no further purchase; the 5-DSI-TOUCH-A (sprint item 10) is its panel.
- **Analog I/O as the pedal's interface, not a novelty (idea 2026-10-23).** The kit's
  PCM5100 and amp were set aside because the S3 has no headroom to spend and the USB
  interface was the point. On the P4 the codec path can be the guitar path: TRS in and out
  through an I2S ADC and DAC on the pedal's own clock, so no USB device, no ring drift, one
  block of latency each way, and a board that is a pedal without an interface plugged in.
  Sequence in `docs/p4.md` ("Sequence"): the POE-ETH's ES8311 proves codec-as-interface
  first (its mic in, its speaker out, no new parts), then a breakout with real line I/O. Chip
  choice is open: ES8388 or a second ES8311 (stereo or mono, `esp_codec_dev` drivers exist,
  the targets tree already has an ES8311 binding, so the Gea side is a sibling binding);
  PCM5102 plus PCM1808 (no control bus at all, track D's codec-less binding shape, PCM1808
  wants a 256fs MCLK); WM8960 (stereo in and out with a headphone amp, no `esp_codec_dev`
  driver, so a new driver as well as a binding). Whatever the chip, a guitar needs an
  analog front end the breakouts do not have: a high-impedance buffer with gain and a
  mid-rail bias before a line-level ADC, and the output wants a buffer to drive a pedal
  chain or an amp. That is the analog pedal build on the side meeting this project.
  Coyopedal side: today the only audio device is the USB host; the codec becomes a second
  device behind the same interface (`docs/p4.md` step 2 is where it lands). Stretch goals,
  in order of cost:
  1. **Multiple IRs and a slider.** Convolution is linear, so a blend of two IRs is one
     convolution of the blended IR, recomputed when the slider moves: cheap even on the S3,
     and the pedal already loads user IRs from `/ir` on the card. A coyopedal feature, no
     hardware.
  2. **IR capture.** Play a sweep out, record the return, deconvolve: the loopback probe
     (`src/audio/loopback_probe.hpp`) already does the first two and measures the delay. Works
     through the USB interface today as well as through a codec later; offline math, not
     real time. A coyopedal feature; the codec only makes the cabling obvious.
  3. **Model capture.** Recording the DI and the reamped pair to the card is the pedal's part;
     NAM training is minutes on a GPU and not a P4 job. Capture on the pedal, train on the
     Mac, upload the model: a workflow, two small pedal features and a host script.
- Decide whether the camera stays once two of its pins carry the panel.
- 4.3B footswitch: wire a stomp switch to the isolated DI0 and test whether the CH422G
  reports it with EXIO0 latched high (`initialOutputs` 0x1f) while the other lines stay
  outputs (or with the whole bank switched to input between card accesses, since the four
  outputs idle high; check the datasheet for an input-mode pull-up first). If not, the
  schematic gives three reclaimable GPIOs with nothing to remove, all soldered on the bottom
  side or the module castellations: 43 (RS485 receive, at R64), 15 (CAN transmit, at the
  TJA1051's pin 1) and 6 (RTC interrupt, at the PCF85063's pin 4; also the only ADC1 pin).
  Track A first: the ES8311 stopgap claims those pins. Knobs as encoders on the I2C header,
  not pots (`docs/waveshare-43b.md`, "Controls beyond touch").

### Upstream coyopedal (after hardware results)

- **Upstream merged 2026-10-23** (`94caeac` on `lavfin-kit-notes`; the clone now has an
  `upstream` remote and `main` mirrors it). Three commits: identifiers renamed to coyopedal,
  Full-Speed audio notes, and the Geastack stack pinned at cli and targets 0.1.108, core
  0.1.49, compiler 1.0.46. The fork's installed node_modules are still cli 0.1.89, targets
  0.1.87, core 0.1.35: the headless `lafvin` build has never been made on upstream's stack.
  Host tests pass on the merge (35 audio, three USB fixtures, loopback probe). **Before any
  pedal PR:** `npm ci`, rebuild the headless `lafvin` target on the pinned stack, and run the
  MOMIX streaming check again; that is the validation the PR's hardware-testing statement
  rests on. Divergence: 34 commits, 29 files, mostly `src/native` and the USB tests.
- **PR dependency notes.** The UAC1, WPA3, status-NaN and footswitch-setting PRs depend on
  nothing upstream and can go first. The 4.3B board definition depends on Gea PRs being
  merged *and released* (the gift targets#5, G cli#7 and targets#6, then H, I, A, J): the
  definition declares no codec (A) and a microSD slot on SPI (G), so on the stock packages
  it does not build. Say so in the PR text, with the PR numbers. The LAFVIN display
  definition likewise waits on B and C.
- Outreach to the author (sequence in `docs/audio/usb-audio.md`, "iRig HD 2 profile retirement"), then the UAC1 PR
  with a hardware-testing statement, README board table, `docs/USB_AUDIO.md`, skill updates.
- WPA3 commit `e6dc162` goes in the same conversation; its message is written to be the PR text.
- From the 4.3B work (`docs/waveshare-43b.md`): the status NaN fix (fork `42e125f`), the
  footswitch as a board-block setting, and the question of an explicit API-only build for a
  headless, switchless pedal that boots into maintenance (the matrix in "The footswitch
  decision"); raise the last as a question, not a change.

### Docs and tooling

- Branch model adopted 2026-10-23 (`docs/branching.md`); topics rebased, H and I cut, K
  dropped, PR branches pushed the same day. Left: cut tracks B and C as topic branches off
  upstream main, so `lafvin-composed-display` becomes a pure integration branch; push the
  integration branches for backup; delete the `pre-rebase-*` tags after the next 4.3B build.
- When a piece of work goes upstream, fold what its readers need into that repository's
  canonical docs (README board table, `docs/USB_AUDIO.md`, the skills); the account of how it
  was found stays here.
- Rotate the API key that was in `~/.zshrc` (user's item).

## Done

- 2026-10-08: kit evaluated; pin map; decision for the headless-first route; generic UAC1
  discovery written and host-tested against the custom-firmware fixture.
- 2026-10-09: ESP-IDF 6.0.2 on `/Volumes/idf6`; AMOLED and LAFVIN targets build (3.07 MB and
  1.95 MB); photos removed from the tree (asset packer lesson); pinout transcribed; devkit
  power override; SD mount reads board pins; MOMIX stock firmware dumped live and added as a
  fixture with a test variant; libusb discovery fixed in the dump script and `.zshrc`;
  in-pedal MOMIX flashing designed.
- 2026-10-10: first boot on the kit's dev board over the CH343 port (USB serial registered on
  the `lafvin` alias); the stock MOMIX enumerates, UAC2 declines, UAC1 adopts; the live
  configuration descriptor is byte-identical to the fixture (215 bytes); streaming clean at
  48 kHz (cap = play every 5 s window, 0 errors, 0 missed blocks, both cores at 87% of the
  1333 us block). Sprint "first light" items 1 to 6 closed; latency judged by ear.
- 2026-10-11: Wi-Fi diagnosed: reason 15 on the WPA2/WPA3 transition router with a correct
  passphrase; the pedal's PMF flag is a no-op on IDF 6 and the Gea base turns SAE off. WPA3
  enabled in the app's sdkconfig (`e6dc162`), +47 KB. Factory asset packers made idempotent so a
  no-op build no longer relinks (`29ee4f9`). The gateway's guest network refuses the pedal at
  authentication (reason 2) under both WPA2-only and transition settings; abandoned.
- 2026-10-12: upstream Geastack surveyed for the display path (`docs/display.md`); tracks A to
  E defined. Workspace moved to `/Volumes/idf6/pedalboard`, forks cloned beside the pedal.
  Tracks B and C written in the forks (host-tested, not yet built into the pedal); the
  display board variant added to the pedal. This repository created; the project notes moved
  here from `coyopedal/docs/lavfin/` and split by topic.
  The display variant then built and linked against the forks through a side framework stack
  (`docs/display.md`, "First fork build"); two more upstream fixes fell out (odometer, source
  walk). Wi-Fi: a Mac sniffer capture showed SAE succeeding with hash-to-element and the
  pedal deauthenticating after handshake message 3 with reason 17, the gateway's WPA3
  compatibility-mode override element differing from its beacon (`docs/wifi.md`); a
  diagnostic image with a frame tap, supplicant debug and a reconnect backoff was built.
  Then: reason 4 and the gateway's retransmissions showed the uplink was the blocker, and the
  module's bridged antenna-selection pads were found and separated; the pedal joins the main
  network and answers `status` and `ota`. The compatibility-mode opt-out stays as a real fix.
  Confirmed: unaided join from the carrier on the first try, OTA round trip validated and
  rebooted into the new slot. Sprint "Wi-Fi tail" item 1 closed. Diagnostics removed from the
  source afterwards (the images remain in `images/`).
- 2026-10-15: the Waveshare ESP32-S3-Touch-LCD-4.3B arrived and track F ran on it the same
  day: the gift branch rebased on upstream main, a `build-config.json` entry and a board page
  added, the counter starter built on upstream's published stack, flashed over the native USB
  port, panel and GT911 up on the first boot, counter rendered at 800x480 and counting on
  injected taps and on fingers (`docs/waveshare-43b.md`). Only the PR remains.
- 2026-10-16: the gift branch rebuilt and reflashed on upstream's current main, same result.
  Track G written and verified the same day: the composer takes a microSD slot on SPI with
  the chip-select on a GPIO or an expander line, the base mounts it through the SDSPI host,
  the 4.3B and 7-inch definitions declare theirs; a file pushed over USB to the 4.3B's card
  and listed back (`docs/waveshare-43b.md`, "Track G"). Sprint item 8's first step is done.
- Night of 2026-10-16: the pedal fork built for the 4.3B on the published stack and ran on
  it: app-local board definition with the codec stopgap and the SPI card, the footswitch now
  follows the board's launcher button and a board without one boots into maintenance; the
  RGB panel needs direct PSRAM scanout on the pedal (no internal RAM for bounce buffers),
  then the UI runs at 15 fps. Wi-Fi joins; the Mac could reach nothing on the LAN, so the
  measurement waits (`docs/waveshare-43b.md`).
