# USB audio: discovery, pacing and the interfaces we know

Paths with no repository prefix are in `coyopedal/`; the forks are named where they are meant.

## USB audio in the pedal (facts from `src/native/drivers/usb_audio.cpp`, `uac2.hpp`)

- The ESP32-S3 host is Full Speed only. High Speed devices still enumerate: they attach at
  Full Speed and only switch up after a chirp handshake the S3 never answers. What differs per
  device is whether its Full Speed configuration offers 48 kHz duplex alternates.
- Generic discovery is UAC2 only (interface protocol 0x20, AudioControl header bcdADC 2.00).
  Tested at Full Speed: XTONE Pro and iRig HD X (both UAC2). The only UAC1 path is the iRig
  HD 2 profile, keyed by VID 0x1963 PID 0x0033, with hard-coded interfaces, alternates and
  endpoints, 3-byte capture frames and 4-byte playback frames, and an unconditional endpoint
  SET_CUR sampling-frequency request.
- Transport limits for any class: 48 kHz only, duplex only, one shared clock, 1 ms packets with
  at least 48 frames, capture at most 96 frames per packet, FIFO fit.
- Generic UAC1 plan: parse AC header 1.00, terminals, feature units, AS general (PCM), Format
  Type I (channels, subframe, bits, discrete rate list including 48000), isochronous endpoints
  with sync type and optional feedback, CS endpoint attributes; reuse pairing and capacity
  checks; send the endpoint rate request only when the CS endpoint reports that control;
  unmute feature units with the existing request shape; configure the same codec objects the
  UAC2 path uses and reuse its ring and pacing logic (frame cadence when there is no feedback).
  Test with a fixture in `tests/usb/` under the sanitizers before touching hardware.

### Other interfaces on hand

| Interface           | Assessment                                                                                                   |
| ------------------- | ------------------------------------------------------------------------------------------------------------ |
| Scarlett (2nd gen+) | UAC2 class compliant; works today if its Full Speed config has 48 kHz duplex                                 |
| MOTU 828 (model?)   | 828es/828x have class-compliant modes, mk3 Hybrid needs a driver; 28 channels do not fit a Full Speed packet |
| VoiceLive Rack      | 2-channel 16-bit 44.1/48 kHz, works on iPad, so class compliant and almost certainly UAC1                    |
| Rig Kontrol 3       | Proprietary NI driver, not class compliant                                                                   |
| GR-55               | Roland driver for audio, 44.1 kHz; refused by the 48 kHz rule                                                |

## Design notes (proposed, 2026-10-08)

- Generic UAC1 discovery, descriptor-driven like the UAC2 path, is the right shape. Flash is
  not the constraint; the pedal's scarce resources are internal SRAM and IRAM on the audio hot
  path, and discovery runs once on the USB setup task (6 KiB stack) with small vectors that
  land in PSRAM under the sdkconfig heap policy. The iRig HD 2 profile is a historical
  exception ("predates UAC2 support"), not a pattern to extend.
- Device quirks, when a device needs one, go in a small table in code keyed by VID:PID, as
  `snd-usb-audio` does, not in a config file on the SD card. SD mounting is deliberately
  deferred until after the NAM banks are placed, to keep driver allocations out of internal
  SRAM, and USB discovery should not depend on it. Quirks are behaviours, which belong next to
  the code they alter and under the host tests.
- Keep the HD 2 profile until its descriptors are captured and the generic path is shown to
  handle it; we cannot test that device ourselves.
- Streaming: a generic UAC1 device should run through the same codec objects, ring targets and
  pacing as UAC2, with the class version only choosing the control-request dialect. The
  existing `Uac1` branches encode HD 2 specifics (3-byte capture, 4-byte playback frames).
- Tests (done): `tests/usb/uac1_test.cpp` runs against both MOMIX fixtures from `scripts/test.sh`.
- Conventions when this goes upstream: CONTRIBUTING.md (`npm run check`, `npm test`, warning-free
  firmware build, clang-format 22.1.8, a hardware-testing statement in the PR), the CLA bot
  comment, and fold these notes into the canonical places: README board table,
  `docs/USB_AUDIO.md` (Discovery, Tested interfaces, Known limits) and
  `skills/building-pedal-firmware/SKILL.md`. Until then everything stays in this repository.

## Per-device timing: a standard method (proposed)

The host cannot resample. Both cores run near their budget, so there will never be an
asynchronous sample-rate converter in the pedal; 48 kHz and one shared clock stay hard rules.
What the host can do is choose how playback is paced, measure, and document. The method:

1. **One pacing ladder, fed from descriptors.** Feedback endpoint when the device has one;
   otherwise capture-paced playback for an asynchronous OUT endpoint on a shared clock (the
   XTONE case); otherwise the USB frame cadence of 48 frames per ms (adaptive and synchronous
   endpoints, and the iRig HD 2). This exists for UAC2 in `usb_audio.cpp`; generic UAC1 must
   feed the same ladder from its own descriptors rather than add a path.
2. **Read the clock from the heartbeat.** When IN packets vary in size, `cap=+N` per 5 s
   gives the device clock against the S3: `N - 240000` frames per 5 s, so `+240024` is
   +100 ppm. Harmless when playback is capture-paced or feedback-driven. For a fixed-size IN
   endpoint such as the MOMIX, N is always exactly 240000 and the device's internal drop or
   duplicate is invisible to the host. Document this interpretation in `docs/USB_AUDIO.md`.
3. **Loopback glitch test** (to add, as an `AUDIO TRY` option): play a tone, loop the
   interface's output back to its input with a cable, and count discontinuities in the
   captured sine with the two-sample recurrence `x[n] = 2 cos(w) x[n-1] - x[n-2]`. Report
   glitches per minute and the implied drift (a 32-sample drop every T seconds is
   `32 / (48000 T)` ppm). It is the only host-side way to see device-internal drop or
   duplicate, and it needs no gear beyond a TRS cable. Runs with the DSP bypassed.
4. **Quirk table, code, keyed by VID:PID**, with timing fields only when a device proves it
   needs them: pacing override and ring depth. Nothing else is in the host's power.
5. **Device-side contract for hackable interfaces**, documented: expose the real clock
   (variable-size IN packets or a feedback endpoint), or lock the audio clock to USB SOF;
   48 kHz; 1 ms packets of at least 48 frames; one clock for both directions. Verify with
   steps 2 and 3.

Upstream shape: three separate PRs. Generic UAC1 with fixtures and tests; the clocking
section, heartbeat interpretation and loopback test; the LAFVIN target. Each one only after
it works well on the hardware here.

## iRig HD 2 profile retirement (plan)

No public descriptor dump of the HD 2 (1963:0033) exists and we have no unit. Plan: a quirk
table keyed by VID:PID whose HD 2 entry reproduces the profile's choices exactly (capture
interface 2 alt 2, playback interface 1 alt 1, rate request sent unconditionally and allowed to
fail, playback trimmed to the startup fill), then delete the fixed-profile code.
Descriptor-level equivalence needs a dump from an HD 2 owner as a fixture; streaming equivalence
needs the device, which upstream has. Sequence agreed 2026-10-09: before any PR, write to the
author about the work, ask for a descriptor dump of his HD 2 (the branch's own maintenance log
dumps it, or `lsusb -v`), and ask whether he wants to test, with a plain account of the
streaming and latency state: the generic path uses the UAC2 ring targets and frame-cadence
pacing where the profile trimmed to the startup fill. For that test the fork needs a switch that
routes the HD 2 through the generic path instead of the VID:PID profile. Offer the PR only if
that comes back good.
