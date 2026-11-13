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
rate_control: "none (CS endpoint attributes 0x00 on both 0x03 and 0x83); no rate request sent"
discovery: "uac1 (uac2 declined it)"
pacing: "frame-cadence"
heartbeat_window_s: 5
stream_errors: 0
missed_blocks: "0/0"
core_load_pct: "87/87"
latency_ms: "30 to 37"     # loopback round trip incl. the pedal rings, 2026-10-24
loopback_glitches_per_min: 0   # 2026-10-24, three 120 s windows, inside the bursts; edge artifacts noted in section 5
drift_ppm: "+54 to +56"    # loopback probe 2026-10-24, three windows: +53.5, +55.8, +56.5
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
      the appendix of `../momix.md`.
- [x] Layout: IAD, control on interface 0, streams on 1 and 2. Playback stereo 16-bit 48 kHz,
      adaptive, EP 0x03, 192 bytes. Capture mono 16-bit 48 kHz, asynchronous, EP 0x83, 96
      bytes, fixed size. Selector units 7 and 8 between the feature units and the output
      terminals. 50 mA declared. JieLi AC6926A4 inside.
- [x] Vendor claim: 48 kHz 16-bit; matches.
- [x] Hard rules on paper: passes (48 kHz duplex, one clock, 96-byte mono capture packets fit
      `fullSpeed48k`).
- [x] `tests/usb/uac1_test.cpp` runs discovery against this fixture and the custom-firmware
      one under the sanitizers.
- [x] Sampling-frequency control: neither endpoint advertises it (CS endpoint attributes 0x00
      on OUT 0x03 and IN 0x83), so the pedal sends no rate request; the device is one-rate.

## 2. Discovery on the pedal

- [x] 2026-10-10: UAC2 declines, UAC1 adopts; capture is channel 0 through the generic frame
      loop.
- [x] Live configuration descriptor byte-identical to the fixture.
- [x] Rate request: not sent (no control bit on either endpoint).
- [ ] Feature-unit unmute and 0 dB requests: outcome not recorded on the sheet yet; read the
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
      100 ppm; see `../momix.md`, "MOMIX drift"). Measured 2026-10-24 by the loopback probe:
      **+53 to +56 ppm** against the kit's S3 (the stock capture endpoint is asynchronous, so
      the device's crystal sets the capture rate and the round trip creeps by about 190 frames
      over a two-minute window). The earlier expectation of 0 ppm was wrong: no adaptation
      means the drift is visible, not absent.

      **note**: A ood write up  including a diff of the fix which includes the calculation used at https://github.com/robmurru/Joyo-MOMIX-CAB-Custom-Firmware/issues/1

      So if drift is ~54.5ppm for our unit, the interval would be
      1 / (54.5 × 1e-6)
      so,
      
      ```
      // repo: robmurru/Joyo-MOMIX-CAB-Custom-Firmware
      // file; src/apps/cpu/audio/ladc.c
      #DEFINE USB_MIC_SKIP_INTERVAL = 5459 
      ```

## 5. Loopback glitch test

- [x] Run 2026-10-24 (Oct 14 image `7f3cbcb`, kit dev board, stock MOMIX, 1/4" TS to 1/8" TRS
      cable from the headphone out to the guitar in). Two usable 120 s windows, both with
      `AUDIO TRY 120 LOOPBACK LEVEL 2` (tone at -2 dBFS; at the default -12 dBFS the return
      sat at -37 to -42 dBFS, under the probe's -34 dBFS floor, and nothing locked):
      round trip 1,449 to 1,594 frames (30.2 to 33.2 ms) on the first burst, 1,645 to 1,776
      (34.3 to 37.0 ms) on the last, drift +53.5 and +55.8 ppm, **0 glitches in about 80 s of
      analyzed frames once the onset settled** (the counted 700 to 4,000 were clipped samples
      in the first 50 ms or after a level change, not drops). The latency includes the pedal's
      rings. Caveat that shaped the night: the stock firmware's always-on monitor plus the
      loopback cable is a regenerative loop; above a device volume that returned the tone at
      about -20 dBFS it oscillated to full scale between bursts (`not_quiet`, `waiting` at 0
      dBFS). The usable band is a return of -26 to -30 dBFS: tone at -2 dBFS, device volume
      at or below its post-connect default, no + presses. The volume buttons move the level
      about a decibel a press and the setting outlived a software reboot of the pedal. Rob
      Murru's firmware, which removes the monitor, is the clean way to run this test.
      Confirming clean window, 05:31, cable in from the start and unplugged for a few bursts
      in the middle (hence 7 locked of about 11): 0 clipped, 0 busy bursts, 0 noise onsets:
      1,470 frames (30.6 ms) first, 1,638 (34.1 ms) last, +56.5 ppm, return -21.2 dBFS, the
      line between bursts at -25.7 dBFS, the loop's tail decaying instead of ringing up. Why
      this window stayed under unity when the one before it at the same -21 dBFS return did
      not: ten - presses between them moved the master by less than the readout resolves, and
      that was enough. The loop sits at unity; a fraction of a decibel decides it, so a pad in
      the cable (a pot as a divider, 6 to 10 dB) is required for repeatable runs, not optional.
      645 glitches counted, every one at a burst edge in
      pairs 400 frames apart at the ten-second cadence and none inside a burst: the monitor's
      echo landing on the edges, which the host test's clean case does not have. A guard band
      around the edges is the probe refinement to make; the steady-state count is 0.

## 6. Latency and signal path

- [x] By ear: passes (2026-10-10).
- [ ] Measured round trip with `tools/null_test.py --bypass`: not done. It would attribute the
      loopback's 30 to 34 ms: the pedal's share is about 270 frames (under 6 ms: input ring held
      at a packet plus a block, one block in the DSP, output ring at two packets plus a block,
      the `rings=48/160` of the heartbeat), so about 25 ms of the round trip sit in the MOMIX's
      own DAC and ADC buffering under stock firmware. For a player that is the gap between the
      dry monitor copy (a few ms) and the processed copy (about 30 ms); Rob Murru's firmware may
      buffer differently and should be measured the same way.
- [x] Direct monitoring: always on, cab-simmed, in the device's DSP; cannot be removed in
      hardware. Only matters if the MOMIX headphone jack becomes the pedal's output, which is
      what Rob Murru's firmware is for.
- [ ] Levels and noise floor: not measured.

## 7. Verdict and follow-up

- [x] Works, stock firmware, generic UAC1. No quirk-table entry needed.
- [x] LAFVIN dev board in the carrier, 2026-10-10 onward; clean image of 2026-10-12.
- [ ] Open: sections 5 and 6 (measured), and the soak row.
