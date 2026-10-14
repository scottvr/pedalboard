# USB audio: what the pedal does, what it was tested with, what is still open

Paths with no repository prefix are in `coyopedal/`; the forks are named where they are meant.

## State (2026-10-12)

The pedal streams with the JOYO MOMIX CAB on its stock firmware through generic USB Audio 1.0
discovery, written and host-tested on 2026-10-08 and first run on hardware on 2026-10-10. On
the kit's dev board the live configuration descriptor is byte-identical to the fixture in
`tests/usb/`, capture and playback frame counts match in every five-second window, there
are no transfer errors and no missed blocks, and both cores sit at about 87% of the 1,333 µs
block. Latency passes by ear. The loopback and drift measurements below wait for a cable.

## How discovery works now

- The ESP32-S3 host is Full Speed only. High Speed devices still enumerate: they attach at
  Full Speed and only switch up after a chirp handshake the S3 never answers. What matters per
  device is whether its Full Speed configuration offers 48 kHz duplex alternates.
- There are three protocol paths in `src/native/drivers/usb_audio.cpp`: the iRig HD 2 profile
  (fixed interfaces, alternates and endpoints keyed by VID 0x1963 PID 0x0033), descriptor-driven
  UAC2 (`uac2.hpp`, interface protocol 0x20), and descriptor-driven UAC1 (`uac1.hpp`,
  protocol 0x00). UAC2 discovery runs first; when it declines a device, UAC1 discovery takes
  it. The two descriptor-driven paths share the topology model, the pairing, the Full Speed
  capacity check, the feature-unit handling, the PCM codecs and the whole transfer path. The
  class version decides only how the sample rate is negotiated.
- UAC1 has no clock entities, so every stream of a function is given clock 0: a single-function
  UAC1 interface runs both directions from its one crystal. The rate is set per streaming
  endpoint, and only on endpoints whose class-specific descriptor advertises the control; a
  device that clears that bit would stall the request, and a one-rate device has no need of it.
  Feature units are unmuted and set to 0 dB with the same requests the UAC2 path uses.
- Transport limits for any class: 48 kHz only, duplex only, one shared clock, 1 ms packets
  with at least 48 frames, capture at most 96 frames per packet, FIFO fit.
- Cost, measured: the driver object grew by 12.7 KB of code (46.5 KB to 59.3 KB of `.text`),
  no change to data; discovery allocates only on the USB setup task, in small vectors that land
  in PSRAM under the heap policy. Flash was never the constraint; internal SRAM and IRAM on the
  audio hot path are, and discovery touches neither.
- Tests: `tests/usb/uac1_test.cpp` runs discovery against both MOMIX fixtures (stock firmware,
  dumped live; custom firmware, synthesised from the image) from `scripts/test.sh`, under the
  sanitizers. `tools/usb/dump_usb_config.py` produced the stock fixture and parses any device
  on the bench.

## Pacing

The host cannot resample. Both cores run near their budget, so there will never be an
asynchronous sample-rate converter in the pedal; 48 kHz and one shared clock stay hard rules.
Playback pacing is one ladder, fed from the descriptors: a feedback endpoint when the device
has one; otherwise capture-paced playback for an asynchronous OUT endpoint on a shared clock
(the XTONE Pro); otherwise the USB frame cadence of 48 frames per millisecond (adaptive and
synchronous endpoints, and the iRig HD 2). The MOMIX's playback is adaptive with no feedback
endpoint, so it runs at the frame cadence; its capture is asynchronous but fixed at 48 frames
per packet, so no rate information crosses the bus either way. The ring targets and the
trimming rules are the ones the UAC2 path was measured with; the comment block above
`kOutputRingFrames` in `usb_audio.cpp` is the authoritative account of why.

Reading the heartbeat: when IN packets vary in size, `cap=+N` per 5 s gives the device clock
against the S3, `N - 240000` frames per 5 s, so `+240024` is +100 ppm. For a fixed-size IN
endpoint such as the MOMIX, N is always exactly 240000 and any drop or duplicate inside the
device is invisible to the host; only the loopback test below can see it.

## Interfaces assessed

| Interface           | Assessment                                                                                                   |
| ------------------- | ------------------------------------------------------------------------------------------------------------ |
| JOYO MOMIX CAB      | Works, stock firmware, generic UAC1; see `momix.md`                                                          |
| XTONE Pro           | Works upstream, UAC2, no feedback endpoint (capture-paced); the author's bench interface                     |
| iRig HD X           | Works upstream, UAC2                                                                                         |
| iRig HD 2           | Works upstream through the fixed profile; we have no unit                                                    |
| Scarlett (2nd gen+) | UAC2 class compliant; should work if its Full Speed config has 48 kHz duplex                                 |
| MOTU 828 (model?)   | 828es/828x have class-compliant modes, mk3 Hybrid needs a driver; 28 channels do not fit a Full Speed packet |
| VoiceLive Rack      | 2-channel 16-bit 44.1/48 kHz, works on iPad, so class compliant and almost certainly UAC1                    |
| Rig Kontrol 3       | Proprietary NI driver, not class compliant                                                                   |
| GR-55               | Roland driver for audio, 44.1 kHz; refused by the 48 kHz rule                                                |

## Still open

1. **Loopback glitch test**: written 2026-10-13 (pedal commit `7f3cbcb`) as `AUDIO TRY <s> LOOPBACK [HZ <f>] [LEVEL
   <dB>]` (`src/audio/loopback_probe.hpp`, host test `tests/loopback_probe_test.cpp`), not yet
   run on hardware. The DSP steps aside; a 997 Hz tone at -12 dBFS goes out in ten-second
   bursts and the return is checked with the two-sample recurrence `x[n] = 2 cos(w) x[n-1] -
   x[n-2]`, whose residual is zero for any sine and a spike at a dropped or repeated sample.
   Beyond the glitch count it measures what the sheet asks for: each burst starts from phase
   zero, so its return frame against its departure frame is the round-trip latency in
   samples, and the slope of that latency across bursts is the drift in ppm with no guess
   about the size of each jump (a 32-sample drop every 6.7 s reads about -100 ppm). The
   host test checks a clean loop, the MOMIX custom firmware's 32-sample drops, single-sample
   slips at 997 Hz (most caught) and 3 kHz (all caught), an open loop, a round trip longer than
   the gap, and a clipped return. Bench procedure: `skills/measuring-pedal-audio/SKILL.md`,
   "The loopback test".
2. **Quirk table**, in code, keyed by VID:PID, as `snd-usb-audio` does, never a file on the SD
   card (SD mounting is deferred past the NAM bank placement on purpose, and discovery must
   not depend on it). Timing fields only when a device proves it needs them: pacing override
   and ring depth. No device has needed an entry yet.
3. **iRig HD 2 profile retirement.** No public descriptor dump of the HD 2 exists and we have
   no unit. Plan: a quirk-table entry that reproduces the profile's choices exactly (capture
   interface 2 alt 2, playback interface 1 alt 1, rate request sent unconditionally and allowed
   to fail, playback trimmed to the startup fill), then delete the fixed-profile code.
   Descriptor-level equivalence needs a dump from an HD 2 owner as a fixture; streaming
   equivalence needs the device, which upstream has. Sequence agreed 2026-10-09: before any
   PR, write to the author about the work, ask for a descriptor dump of his HD 2 (the
   branch's maintenance log dumps it, or `lsusb -v`), and ask whether he wants to test, with a
   plain account of the streaming and latency state. For that test the fork needs a switch
   that routes the HD 2 through the generic path instead of the VID:PID profile.
   Status 2026-10-12: the author was pointed at this repository and asked for the dump; he
   did not answer that part. He mentioned his iRig HD X runs a custom firmware. The "192/384"
   in the HD X fixture are bytes per packet (48 frames per ms, 16-bit stereo in, 32-bit stereo
   out), not kilohertz; 192 kHz stereo 24-bit would need 1,152 bytes per Full Speed frame,
   above the 1,023 limit. The HD 2 request goes back on the list for the UAC1 outreach.
4. **Device-side contract for hackable interfaces**, to document: expose the real clock
   (variable-size IN packets or a feedback endpoint) or lock the audio clock to USB SOF;
   48 kHz; 1 ms packets of at least 48 frames; one clock for both directions. The MOMIX fix
   that would satisfy it is sketched in `momix.md`, "MOMIX drift".

## Upstream shape

Three separate PRs, each only after it works well on the hardware here: generic UAC1 with
fixtures, tests and the dump tool; the clocking section, heartbeat interpretation and loopback
test; the LAFVIN target. Conventions: `CONTRIBUTING.md` (`npm run check`, `npm test`,
warning-free firmware build, clang-format 22.1.8, a hardware-testing statement in the PR), the
CLA bot comment, and the canonical places that receive the durable parts: the README board
table, `docs/USB_AUDIO.md` (Discovery, Tested interfaces, Known limits) and
`skills/building-pedal-firmware/SKILL.md`. The account of how it was found stays here.
