# JOYO MOMIX CAB

Paths with no repository prefix are in `coyopedal/`; the forks are named where they are meant.

## The device and the custom firmware

- Hardware: JieLi AC6926A4 SoC (512 KiB flash), RS721 input buffer, 1/4" guitar in, 3.5 mm
  headphone out, 48 kHz 16-bit, bus powered 5 V 50 mA. Direct monitoring is done in the DSP
  firmware and cannot be removed in hardware.
- Rob Murru's custom firmware removes the always-on monitor, leaving a plain USB audio
  interface. Caveats: a software rate adapter in `ladc.c` skips one 32-sample DMA block every
  10,000 ISR calls (about 6.7 s) to absorb roughly 100 ppm crystal drift against the host, so
  capture has a periodic 0.67 ms discontinuity by construction; only `DAC_SAMPLE_CON = 0` was
  stable; buttons unmapped; bMaxPower hex-patched to 100 mA.
- Flashing: JL USB Updater dongle (or Arduino emulation of it) to enter UBOOT mode, then the
  repo's Windows `download.bat` (`isd_download.exe` with `0x077A.key`), which needs the "free
  key patch" from the USMI forum. kagaimiq's `jl-uboot-tool` (Python) can read and write flash
  once the chip is in UBOOT mode. Back up the stock flash first; the repo carries a stock dump.

### USB descriptors (extracted from the firmware images, same USB library in stock and custom)

- Device: VID 0xE5B7, PID 0x0811, USB 1.10 (Full Speed), bcdDevice 1.00, EP0 64 bytes.
- Audio function, UAC1 (bcdADC 1.00): interface 1 AudioControl; streaming interfaces 2 and 3.
- Playback: input terminal 1 (USB streaming, 2 ch) -> feature unit 9 (mute master, volume L/R)
  -> output terminal 3 (speaker). Interface 2 alt 1: PCM 2 ch, 2-byte subframe, 16 bit, one
  discrete rate 48000. Endpoint 0x02 OUT, isochronous adaptive, 192 bytes, 1 ms. CS endpoint
  attributes 0 (no sampling-frequency control). No feedback endpoint.
- Capture: input terminal 2 (microphone, 1 ch) -> feature unit 10 (mute and volume, master)
  -> output terminal 4 (USB streaming). Interface 3 alt 1: PCM 2 ch, 16 bit, 48000. Endpoint
  0x83 IN, isochronous adaptive, 192 bytes, 1 ms. CS endpoint attributes 0.
- The configuration header is built at run time by the closed library; the fixture below
  assumes 3 interfaces, total 193 bytes, 100 mA, interfaces numbered from 1. Confirm with a
  live dump from a Mac or from the pedal's maintenance log on the devkit before trusting it.
- Fit with the pedal: 48 frames per packet both ways, 1 ms, same device clock, 48 kHz only.
  Needs generic UAC1 discovery; must not send the sampling-frequency request; playback at the
  USB frame cadence; capture uses channel 0 of the stereo 16-bit stream.

Fixture (now `tests/usb/momix-cab-custom-fw-configuration.bin`; config header synthesized,
function bytes verbatim from `flash/sdk.app` 0x021aa0 to 0x021b58 of the custom firmware
repository):

```text
09 02 c1 00 03 01 00 80 32 09 04 01 00 00 01 01 00 00 0a 24 01 00 01 47 00 02 02 03 0c 24
02 01 01 01 00 02 03 00 00 00 0a 24 06 09 01 01 01 02 02 00 09 24 03 03 01 03 00 09 00 0c
24 02 02 01 02 00 01 01 00 00 00 09 24 06 0a 02 01 03 00 00 09 24 03 04 01 01 00 0a 00 09
04 02 00 00 01 02 00 00 09 04 02 01 01 01 02 00 00 07 24 01 01 01 01 00 0b 24 02 01 02 02
10 01 80 bb 00 09 05 02 09 c0 00 01 00 00 07 25 01 00 00 00 00 09 04 03 00 00 01 02 00 00
09 04 03 01 01 01 02 00 00 07 24 01 04 01 01 00 0b 24 02 01 02 02 10 01 80 bb 00 09 05 83
09 c0 00 01 00 00 07 25 01 00 00 00 00
```

## MOMIX drift: what a proper fix looks like

- Correction to an earlier guess: `DAC_SAMPLE_CON` in the JieLi SDK is only the DAC DMA block
  size exponent (`DAC_SAMPLE_POINT = 32 << DAC_SAMPLE_CON`), not a sync mode.
- The host cannot fix the drift: the IN endpoint is fixed at 48 frames per packet, so no rate
  information crosses the bus, and the device clock is free-running.
- The SDK has the building blocks for a device-side fix: a USB SOF interrupt
  (`IRQ_USB_SOF_IDX`), the closed library's own sync layer (`usb_mic_syn_init`,
  `usb_spk_syn_init`, `ADC_USB_SYN_OPS` and `DAC_USB_SYN_OPS` with `set_frameSize`, in
  `lib_usb_syn.a`), and a sample-rate converter (`src_api.h`). A glitch-free version would
  steer an SRC ratio in the mic path from SOF count versus ADC sample count instead of
  dropping a block every 6.7 s. That belongs in Rob Murru's repository, not here.

## The MOMIX CAB, stock firmware, dumped live (2026-10-09)

`momix-cab-stock-fw-usb-dump.txt` is the parse; the raw 215-byte configuration is
`tests/usb/momix-cab-stock-fw-configuration.bin` and `npm test` runs UAC1 discovery against it.
What the factory firmware presents, against Rob's custom firmware:

|          | Stock                                                                     | Rob's firmware                           |
| -------- | ------------------------------------------------------------------------- | ---------------------------------------- |
| Layout   | IAD, control on interface 0, streams on 1 and 2                           | no IAD, control on 1, streams on 2 and 3 |
| Playback | stereo 16-bit 48 kHz, adaptive, EP 0x03, 192 bytes                        | same, EP 0x02                            |
| Capture  | **mono** 16-bit 48 kHz, **asynchronous**, EP 0x83, 96 bytes               | stereo, adaptive, 192 bytes              |
| Units    | selector units 7 and 8 between the feature units and the output terminals | none                                     |
| Power    | 50 mA declared                                                            | 100 mA                                   |

So the stock device already works with the pedal's generic UAC1 path: discovery adopts it (the
UAC2 module declines it, the fallback takes it), the capture is channel 0 through the generic
frame loop, and `fullSpeed48k` accepts 96-byte mono packets. Nothing in the descriptors
explains the always-on monitor; that is firmware behaviour, which is what Rob's build changes.
His firmware also makes the capture stereo, which the pedal does not need. The custom-firmware
fixture remains a synthesized header around bytes from his image; the stock one is real.

## Planned: flashing the MOMIX from the pedal (decided 2026-10-09)

The pedal should be able to put Rob Murru's firmware onto a stock MOMIX CAB by itself, from
maintenance mode, with the interface plugged into the pedal's own host port. Design sketch:

1. **Prerequisite:** the manual route must have worked first on at least one unit: a USB-C
   breakout, the MOMIX's D+ and D- on two GPIOs of any spare dev board for the key wiggle, VBUS
   and ground from the Mac so the chip never loses power, then `jl-uboot-tool` on the Mac to
   read the backup and write Rob's `flash/jl_692x.bin`. The pedal version only reproduces what
   that proved.
2. **Entering UBOOT:** the JieLi updater dongle is a bit-bang of the 16-bit key 0x16EF on D+ and
   D- (clock on one, data on the other) until the chip acknowledges by pulling both low for one
   to two milliseconds; see kagaimiq's `how-to-enter-uboot.md` and Christian Kramer's AC690X
   repository for the timing. On the pedal this means detaching the USB PHY, driving GPIO 19
   and 20 as plain outputs for the wiggle, then handing them back and installing the host stack.
   Maintenance boots do not install the USB host today, so this runs as its own bounded boot,
   the way `AUDIO TRY` does.
3. **Talking UBOOT:** the chip enumerates as a mass-storage-style device (product strings
   `UBOOT`, `UDISK` or `DEVICE` in kagaimiq's tool). The protocol is bulk-only transport: a
   command block out, a data phase, a status block in, with the vendor SCSI opcodes
   `jl-uboot-tool` sends. A few hundred lines on top of the pedal's existing host stack; no
   general SCSI or filesystem code.
4. **Safety:** read all 512 KiB to the SD card first, refuse to proceed if the read fails or
   the SD card is absent, write, read back and compare, and say plainly in the command's reply
   what is about to be written into whose hardware. Test on two units before anyone else runs
   it.
5. **The image:** from the SD card (`/sdcard/momix/`), never embedded in the pedal's flash. It
   contains JieLi's closed SDK libraries and Rob's repository has no license; fetch it at setup
   time with his blessing, as the existing capture fetcher does for models.
6. **Command:** a maintenance-mode `MOMIX FLASH` next to `AUDIO TRY` in `remote_service.cpp`,
   with `MOMIX BACKUP` as the read-only half for people who only want the dump.
