---
device: "JOYO MOMIX CAB"
firmware: "stock"
vid: "e5b7"
pid: "0811"
usb_class: "uac1"
attach_speed: "full"
bus_power_ma: 50
fixture: "tests/usb/momix-cab-stock-fw-configuration.bin"
dumped_on: "2026-10-09"
capture_format: "1ch 16-bit 48k"
playback_format: "2ch 16-bit 48k"
capture_sync: "async (96), fixed size"
playback_sync: "adaptive (192), no feedback endpoint"
rate_control: ""
discovery: "uac1 (uac2 declined it)"
pacing: "frame-cadence"
heartbeat_window_s: 5
stream_errors: 0
missed_blocks: "0/0"
core_load_pct: "87/87"
latency_ms: "by ear"
loopback_glitches_per_min:
drift_ppm: "n/a from the heartbeat (fixed-size IN); loopback pending"
direct_monitor: "always on (cab-simmed, in the device DSP)"
verdict: "works"
tested_on: "2026-10-10"
board: "lafvin dev board"
image: "first-light builds of 2026-10-10; clean image images/lafvin-20261012-7175055-clean.bin"
---

# JOYO MOMIX CAB, stock firmware: test sheet

Filled 2026-10-13 from `../momix.md` and `../usb-audio.md`. Steps not yet run are left
unchecked; the cable for section 5 arrived 2026-10-13.

## 1. Identity and descriptors

- [x] Dumped live on the Mac 2026-10-09 with `tools/usb/dump_usb_config.py`; 215-byte
      configuration, fixture `tests/usb/momix-cab-stock-fw-configuration.bin`; the parse is
      `momix-cab-stock-fw-usb-dump.txt`.
- [x] Layout: IAD, control on interface 0, streams on 1 and 2. Playback stereo 16-bit 48 kHz,
      adaptive, EP 0x03, 192 bytes. Capture mono 16-bit 48 kHz, asynchronous, EP 0x83, 96
      bytes, fixed size. Selector units 7 and 8 between the feature units and the output
      terminals. 50 mA declared. JieLi AC6926A4 inside.
- [x] Vendor claim: 48 kHz 16-bit; matches.
- [x] Hard rules on paper: passes (48 kHz duplex, one clock, 96-byte mono capture packets fit
      `fullSpeed48k`).
- [x] `tests/usb/uac1_test.cpp` runs discovery against this fixture and the custom-firmware
      one under the sanitizers.
- [ ] Which endpoints advertise the sampling-frequency control: read it off the parse and
      fill `rate_control`.

## 2. Discovery on the pedal

- [x] 2026-10-10: UAC2 declines, UAC1 adopts; capture is channel 0 through the generic frame
      loop.
- [x] Live configuration descriptor byte-identical to the fixture.
- [ ] Rate request outcome and feature-unit requests: not recorded on the sheet yet; read the
      first-light log.
- [x] Pacing: frame cadence (adaptive OUT with no feedback endpoint; asynchronous IN but fixed
      at 48 frames, so no rate information crosses the bus either way).

## 3. Streaming

- [x] 2026-10-10 first light: `cap` = `play` in every 5 s window, `err` 0, `miss=0/0`, both
      cores at about 87% of the 1,333 µs block.
- [ ] First four capture completions: not recorded here.
- [ ] Ten-minute soak with the heartbeat watched: not recorded as such (the board has streamed
      for long sessions in the carrier since 2026-10-10 with no complaint; make it a measured
      row).
- [ ] Hot plug matrix.
- [x] Bus power: 50 mA declared, fine on the dev board's OTG port.

## 4. Clock and drift

- [x] n/a from the heartbeat: the IN endpoint is fixed at 48 frames per packet, so N is
      always 240000 and any drop or duplicate inside the device is invisible to the host.
- [x] Clocks: one crystal, free-running; the device applies no rate adaptation in stock
      firmware (Rob Murru's custom firmware skips a 32-sample block every 6.7 s to absorb about
      100 ppm; see `../momix.md`, "MOMIX drift").

## 5. Loopback glitch test

- [ ] Not run. The 1/4" to 1/8" TRS cable arrived 2026-10-13; the counting `AUDIO TRY` option
      is not written yet (`../usb-audio.md`, "Still open", item 1). Keep the input below full
      scale.

## 6. Latency and signal path

- [x] By ear: passes (2026-10-10).
- [ ] Measured round trip with `tools/null_test.py --bypass`: not done.
- [x] Direct monitoring: always on, cab-simmed, in the device's DSP; cannot be removed in
      hardware. Only matters if the MOMIX headphone jack becomes the pedal's output, which is
      what Rob Murru's firmware is for.
- [ ] Levels and noise floor: not measured.

## 7. Verdict and follow-up

- [x] Works, stock firmware, generic UAC1. No quirk-table entry needed.
- [x] LAFVIN dev board in the carrier, 2026-10-10 onward; clean image of 2026-10-12.
- [ ] Open: sections 5 and 6 (measured), and the soak row.
