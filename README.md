# a NAM guitar pedal on the LAFVIN ESP32-S3 Multimedia Kit (based on coyopedal)

This is the working "umbrella" repository for everything the project touches that is not one repository's own
business: the kit, the hardware mod, the JOYO MOMIX CAB interface, the Geastack changes that
let a composed board drive the kit's panel and touch, the bench procedures, and what was
learned on the way. Code lives in the repositories below; this one holds the plan, the notes
and the reasons, in prose, so that someone adding a board to the pedal or to Gea does not
have to reconstruct the process from commit messages.

In an impressive feat, `dashersw` released [coyopedal](https://github.com/dashersw/coyopedal), NAM on an ESP32-S3 with the Waveshare ESP32-S3-Touch-AMOLED-2.06 as the reference board. Not having one on hand, I grabbed the first unused suitable-looking kit from the pile and forked coyopedal for a "quick" adjustment of a board definition, or so I thought.

Turns out that what was on hand was not nearly as similar as I had assumed: some hardware hacking is involved, as qould be plenty of code. Now, first-class UAC1 is supported broadly without vendor-specific code, and the three of the `geastack` repos got dragged in so that we could support the TFT display and the capacitive touch chip, among othert things including some deep wifi wild goose chasing which you can read about if you are so inclined.

| Directory    | What it is                                                         | Upstream                    |
| ------------ | ------------------------------------------------------------------ | --------------------------- |
| `coyopedal/` (branch `lafvin-kit-notes`) | The NAM pedal firmware                | github.com/dashersw/coyopedal  |
| `cli/`  (branch `lafvin-composed-display`)     | Fork of `@geastack/cli` (`gea` CLI, the custom-target composer)    | github.com/geastack/cli     |
| `targets/`  (branch `lafvin-composed-display`) | Fork of `@geastack/targets` (board sources, ESP32 bindings)        | github.com/geastack/targets |
| `core/` (branch `lafvin-composed-display`)     | Fork of `@geastack/core` (`packages/chips` holds the chip catalog) | github.com/geastack/core    |

The four are plain sibling clones, gitignored here, - not submodules that will apear on your disk if you clone this repo. `BACKLOG.md` ("Upstream
tracks") records which branch of each fork carries what, what it has run on thus far and (eventually) any PRs, which
should be all a reader needs to find the code do DIY. Forks live under github.com/scottvr; clone them here
with `gh repo clone scottvr/<name>`, which adds the `upstream` remote.  When the code is complete and tested I will submit PRs to have the work upstreamed. If for whatever reason the PRs are not accepted, I'll merge the branches here into main in these forks and just maintain the new divergent versions here.

## Where to read

- `BACKLOG.md`: cadence, the current sprint, the upstream tracks table, the backlog, the done
  log. Start here for what happens next.
- `docs/kit.md`: the kit, its carrier pinout (photos in `docs/photos/`), why the native USB
  pins matter, the hardware mod, the boards on hand.
- `docs/display.md`: the plan for the 2.8" panel and FT6336 touch through Geastack composed
  targets, and what the forks carry.
- `docs/geastack.md`: how app-local composed targets work, what upstream lacks, the headless
  milestone, the blockers found.
- `docs/audio/usb-audio.md`: the pedal's USB audio discovery and pacing, the interfaces assessed,
  the proposed timing method, the iRig HD 2 retirement plan.
- `docs/audio/momix.md`: the JOYO MOMIX CAB, its stock and custom firmware, the drift, and the plan
  to flash it from the pedal.
- `docs/audio/device-sheet-template.md`: the per-interface test sheet (checklist and values);
  filled sheets live in `docs/audio/devices/`, one per interface, with the values in front
  matter so a table can be generated from them later.
- `docs/wifi.md`: joining the maintenance network, finding by finding.
- `docs/build-environment.md`: ESP-IDF on this Mac, the aliases, the fork bench workflow.
- `docs/p4.md`: the project after the kit, NAM on an ESP32-P4: what the chip changes, where
  Geastack stands on it, the boards on hand and to buy, the courtesy question for upstream.
- `docs/sources.md`: everything read on the way.

## Status

- The pedal runs on the LAFVIN kit's dev board (first boot 2026-10-10) and streams audio with
  the stock JOYO MOMIX CAB through the new generic UAC1 path: the live configuration descriptor is
  byte-identical to the fixture in `tests/usb/`, capture and playback counts match in every
  5s window, no errors or missed blocks, both cores at about 87% of the 1333 us block. Latency
  passes (by ear until a loopback test is perforked ,which we expecct will validate theh ear-reading).
- The board has been seated back in the carrier for these runs after some minor cosmetic surgeery and a bit of hobbling,
  with the native USB OTG port hosting the MOMIX; the display, touch and speaker need the upstream Geastack work tracked
  in `BACKLOG.md` ("Upstream tracks") before they can be used. The design is in `docs/display.md`.
- Maintenance mode over Wi-Fi: the AT&T gateway runs WPA2/WPA3 transition mode and left the
  four-way handshake unanswered until WPA3 was compiled in (commit `e6dc162`; see `docs/wifi.md`). The main-network test with that build is the next bench item.
- The working list is `BACKLOG.md`: current sprint, upstream tracks, backlog,
  done log.
- Rob Murru's custom MOMIX firmware is only needed when the MOMIX headphone jack is the
  pedal's output (it removes the always-on cab-simmed monitor). Generic UAC1 discovery lives in
  `src/native/drivers/uac1.hpp`, wired into `usb_audio.cpp` as the fallback when UAC2
  discovery declines a device, with a host test against the MOMIX fixture. Measured cost: the
  driver object grows by 12.7 KB of code (46.5 KB to 59.3 KB of `.text`), no change to data,
  and discovery allocates only on the setup task.
