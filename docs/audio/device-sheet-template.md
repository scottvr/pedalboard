---
# One sheet per USB audio interface tested with the pedal. Copy this file to
# devices/<maker>-<model>.md, fill the values below, then work the checklist in the body.
# Keep the keys as they are: a script will read every sheet's front matter and render the
# "Interfaces assessed" table in usb-audio.md from it. Unknown: leave the value empty.
# Not applicable: write n/a. Never guess a value; write how it was measured in the body.
device: ""                 # maker and model as printed on the unit
firmware: ""               # stock | custom (whose) ; version if the device reports one
vid: ""                    # hex, four digits, e.g. e5b7
pid: ""                    # hex, four digits
usb_class: ""              # uac1 | uac2 | profile (name) | not class compliant
attach_speed: ""           # full | high-attaching-at-full (S3 is Full Speed only)
bus_power_ma:              # bMaxPower as declared
fixture: ""                # path of the configuration-descriptor fixture in coyopedal/tests/usb/
dumped_on: ""              # YYYY-MM-DD, host or pedal log
capture_format: ""         # channels/bits/rate, e.g. 1ch 16-bit 48k
playback_format: ""        # e.g. 2ch 16-bit 48k
capture_sync: ""           # async | adaptive | sync ; packet bytes in parentheses, e.g. async (96)
playback_sync: ""          # e.g. adaptive (192), feedback endpoint yes/no
rate_control: ""           # which endpoints advertise the sampling-frequency control
discovery: ""              # which path adopted it: uac2 | uac1 | profile | declined (why)
pacing: ""                 # feedback | capture-paced | frame-cadence
heartbeat_window_s:        # length of the clean window the streaming row describes
stream_errors:             # err= total over the window
missed_blocks: ""          # miss=a/b over the window
core_load_pct: ""          # C0/C1 mean as % of the 1,333 us block, e.g. 87/87
latency_ms: ""             # measured round trip; "by ear" until measured
loopback_glitches_per_min: # from the loopback test; empty until run
drift_ppm: ""              # from the heartbeat (variable IN) or the loopback; n/a if unmeasurable
direct_monitor: ""         # none | always on | switchable
verdict: ""                # works | works with caveats | refused | untested
tested_on: ""              # YYYY-MM-DD
board: ""                  # lafvin dev board | amoled 2.06 | p4 ...
image: ""                  # pedal commit or images/ entry the results came from
---

# <Maker model>: test sheet

Paths with no repository prefix are in `coyopedal/`. The pedal's commands and log lines named
below are described in `coyopedal/docs/MEMORY.md` ("AUDIO TRY", "the `audio:` heartbeat") and
`coyopedal/docs/USB_AUDIO.md`. Background for every step: `../usb-audio.md`.

## 1. Identity and descriptors (host, no pedal needed)

- [ ] Plug the interface into the Mac and dump its configuration descriptor:
      `python3 tools/usb/dump_usb_config.py --vid <vid> --pid <pid> --out <fixture>.bin`.
      Commit the `.bin` under `tests/usb/` and keep the parse next to this sheet.
- [ ] From the parse, fill: class version (interface protocol 0x20 is UAC2, 0x00 UAC1),
      layout (IAD or not, control interface, streaming interfaces and their alternates), per
      direction the channels, bit depth, rates, sync type and packet size, feedback endpoint,
      which endpoints advertise the sampling-frequency control, feature and selector units,
      clock entities (UAC2 only), declared bus power.
- [ ] Note what the vendor claims (rates, bit depths) against what the Full Speed configuration
      actually offers. A High Speed device attaches at Full Speed on the S3; only its Full
      Speed alternates matter.
- [ ] Apply the pedal's hard rules on paper before plugging in: 48 kHz, duplex, one shared
      clock, 1 ms packets of at least 48 frames, capture at most 96 frames per packet, FIFO
      fit. Write down which rule would refuse it, if any.
- [ ] Add a discovery test case against the fixture in `tests/usb/` and run `npm test`.

Values: (write them here in prose or a small table; the front matter holds the summary)

## 2. Discovery on the pedal

- [ ] Plug into the pedal's OTG port, boot, read the maintenance `logs`. Record which path
      took the device (UAC2, UAC1 fallback, fixed profile) and the interfaces and alternates it
      chose.
- [ ] Compare the bytes the pedal logged with the fixture: byte-identical, or note the
      difference (a device can present a different configuration to a different host).
- [ ] Rate request: accepted, stalled and tolerated, or not sent (no control bit).
- [ ] Feature units: unmute and 0 dB requests accepted.
- [ ] Record the pacing mode the ladder chose and why (feedback, capture-paced, frame cadence).

Values:

## 3. Streaming (device counters)

- [ ] `AUDIO TRY 45 ENGAGE MASK 63 MODEL <index>` with a demanding preset, then at least six
      complete `audio:` heartbeats after the first thirty seconds. Record per window: `cap`,
      `play`, `silence`, `err`, `miss=a/b`, `C0`/`C1` mean and maximum, ring depths.
- [ ] The first four capture completions: requested and actual packet sizes, status, raw
      isochronous error.
- [ ] Soak: a real audio boot of at least ten minutes with the heartbeat watched. Record any
      drift of `silence`, any `err`, any `miss`.
- [ ] Hot plug: unplug and replug while streaming; power the pedal with the interface already
      attached; attach after boot. Record what recovers and what needs a reboot.
- [ ] Bus power: declared versus what the port can give; any brown-out symptoms.

Values:

## 4. Clock and drift

- [ ] If IN packets vary in size: `cap=+N` per 5 s gives the device clock against the S3,
      `(N - 240000) / 240000` as ppm (`+240024` is +100 ppm). Record N over six windows.
- [ ] If IN packets are fixed size (the MOMIX): the host cannot see drift; write n/a here and
      rely on the loopback test.
- [ ] Which clock does playback follow, and is it the same crystal as capture.

Values:

## 5. Loopback glitch test

- [ ] TRS cable from the interface's output to its input, input gain set so the tone sits well
      below full scale, DSP bypassed. Run the loopback `AUDIO TRY` option (see `../usb-audio.md`,
      "Still open", item 1) for at least five minutes.
- [ ] Record glitches per minute, the implied drift (a 32-sample drop every T seconds is
      `32 / (48000 T)` ppm), and the input level used.
- [ ] Listen to the same loop while it runs; note whether the counted glitches are audible.

Values:

## 6. Latency and signal path

- [ ] By ear with the amp block on: acceptable or not, and against which reference.
- [ ] Measured: record a DI through the pedal with the amp block off and run
      `tools/null_test.py --bypass`, which reports the round-trip latency and the level scaling.
      Record both in ms and samples.
- [ ] Direct monitoring: none, always on (in the device's DSP, as the stock MOMIX), or
      switchable; whether it mixes into the output the pedal plays through.
- [ ] Levels: input clip point against a known source, output level into the next stage, noise
      floor with the input shorted.

Values:

## 7. Verdict and follow-up

- [ ] Verdict for the "Interfaces assessed" table: works, works with caveats (which), refused
      (which rule), untested.
- [ ] Quirk table: does this device need an entry (pacing override, ring depth, rate request
      behaviour)? No device has needed one yet; say so if that still holds.
- [ ] Board, image or commit, date, who ran it.
- [ ] Anything that belongs in `../usb-audio.md` as a rule rather than a device fact.

Values:
