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
| A     | Gate the ES8311 binding on a composed board's audio chip (`GEA_CUSTOM_TARGET_HAS_AUDIO`, fall back to `audio_runtime_stub.cpp`); one-line `GEA_BOARD_HAS_POWER` for `s3-devkit`                                                                | cli, targets        | not started | no              |     |
| B     | SPI panel for composed targets: composer accepts `interface: "spi"` (st7789 first), emits the ST7789 display struct and defines; base CMake includes the sticks3 pipeline; pipeline gains colour order, inversion and optional backlight/reset | cli, targets, chips | `lafvin-composed-display`: cli 5aea1d9, targets c84bff1 f65c525 d107bfb, core 14f08ad | builds, not flashed |     |
| C     | FT6336 touch adapter in the chips catalog; the binding gains the Touchscreen surface (`ft6336_touchscreen.cpp`), viewport mapping and the audio task-priority rule; the base's touch gate already admits any non-FT3168 driver                | chips, targets      | `lafvin-composed-display`: targets ca3372d, core 14f08ad | builds, not flashed |     |
| D     | Codec-less I2S DAC binding for the PCM5100 (I2S half of the ES8311 binding without the codec-dev calls); only if the kit's speakers become the monitor path                                                                                    | targets, chips      | not started | no              |     |
| E     | Ask whether the LAFVIN target belongs in `@geastack/targets` once B and C are in                                                                                                                                                               | targets             |             |                 |     |
| F     | Waveshare ESP32-S3-Touch-LCD-4.3B as a composed board: the 7-inch definition's panel electronics with the B's notes (RS485 on UART0, CAN, isolated I/O, RTC, charger), a `build-config.json` entry and a board page; a small gift PR, asked about by someone on his side (`docs/waveshare-43b.md`) | targets             | `waveshare-touch-lcd-4.3b` (rebased on upstream `9546973`) | yes, 2026-10-15: panel, touch by hand, counter runs | to open |

Each fork is a sibling clone on branch `lafvin-composed-display`; the pedal builds against
them with the command in `docs/build-environment.md`. Design: `docs/display.md`.

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
- Remove the ES8311 stopgap from the LAFVIN definition once track A lands.
- `tools/audio-devices-table.py`: read the front matter of every `docs/audio/devices/*.md`
  sheet and render the "Interfaces assessed" table in `docs/audio/usb-audio.md` from it, so the
  sheets are the single source. Host-side, any time; worth it once a second sheet exists.
- Ask upstream to rename `tools/esp32/amoled_remote.py`: its messages already say "CoyoPedal"
  on any board (fork commit `7b81d9c`) and its discovery match was never board-specific; only
  the file name lags. Low priority, easy ask alongside the UAC1 PR.
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
- Track F: open the gift PR against geastack/targets (`docs/waveshare-43b.md`); the branch
  is verified and pushed.
- Two Waveshare ESP32-P4 boards arrived 2026-10-13: an ESP32-P4-WIFI6-POE-ETH (ES8311 codec,
  Ethernet with PoE, C6 with an IPEX antenna) and an ESP32-P4-Module-DEV-KIT (four USB-A ports,
  Ethernet). Both panel-less, both in `docs/p4.md`. They belong to the next project, below.

### Next project: NAM on the ESP32-P4 (`docs/p4.md`)

Starts after the kit's display and the gift PR. Before any code, ask the maintainer the
courtesy question written in `docs/p4.md` (he has P4 work he is keeping closed). First
milestone: a Gea P4 target's first real run on a board on hand, with the C6 Wi-Fi link up.
The pedal-port board is the POE-ETH on hand: its ES8311 is the pedal's codec, so the headless
boot needs no further purchase; a DSI panel board is optional, later.
- Decide whether the camera stays once two of its pins carry the panel.

### Upstream coyopedal (after hardware results)

- Outreach to the author (sequence in `docs/audio/usb-audio.md`, "iRig HD 2 profile retirement"), then the UAC1 PR
  with a hardware-testing statement, README board table, `docs/USB_AUDIO.md`, skill updates.
- WPA3 commit `e6dc162` goes in the same conversation; its message is written to be the PR text.

### Docs and tooling

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
