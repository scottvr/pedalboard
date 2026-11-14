# Bench displays: what was bought and why (2026-10-19)

The 4.3B's apparent death (`docs/waveshare-43b.md`, "The board's death"; in the end a bad USB
cable, not the board) turned a question into a
purchase: with two bare P4 boards and a drawer of generic ESP32-S3 devkits, which displays
serve the pedal *and* widen Geastack's hardware? Two were chosen. The reasoning is kept here
so the next purchase does not redo it.

## Displays on hand (2026-10-23)

The display inventory, kept so a change to a shared piece (the composer's SPI adapter, a DSI
base, a touch binding) is checked against every panel it reaches before it lands. Boards with
their own panels are listed with the bare panels; the P4 boards themselves are in `docs/p4.md`.

| Display | Interface, panel, touch | Arrived | Serves |
| --- | --- | --- | --- |
| LAFVIN kit 2.8" TFT (in the carrier) | SPI ST7789 240x320, FT6336U capacitive touch on the carrier's I2C | 2026-10-09 | The kit pedal, tracks B and C (`docs/kit.md`, `docs/display.md`) |
| Freenove FNK0104AB ESP32-S3 2.8" display board | SPI ILI9341 240x320 (BGR, inverted), FT6336U touch with INT and reset routed, ES8311 codec with mic and speaker amp, SDMMC 4-bit slot; ESP32-S3R8 (8 MB PSRAM) with 16 MB flash. Pin map below | earlier, noticed in the inventory 2026-11-14 | A second all-in-one S3 for the composer's SPI adapter, and a pedal home with a panel, codec and card on board: track B's FT6336 binding applies as is, the panel needs an ILI9341 sibling of the ST7789 pipeline |
| Waveshare ESP32-S3-Touch-LCD-4.3B | 16-bit RGB 800x480, GT911 touch, CH422G expander; "died" 2026-10-19, but the fault was a bad USB cable on the hub (cable replaced, board runs; recorded 2026-11-14) | 2026-10-15 | Track F's gift board and the pedal's 4.3B home (`docs/waveshare-43b.md`) |
| XIITIA 3.5" ST7796 module, 1 of 2 in hand | SPI ST7796 320x480, 8-pin, 3.3 V, no touch | 2026-10-21 (one seen; the order says two, second unaccounted for as of 2026-10-23) | Display-only pedal on a bare S3; the composer's SPI adapter; one spare or for a P4 |
| Waveshare 5-DSI-TOUCH-A | 2-lane MIPI-DSI HX8394 720x1280, GT911-family touch, I2C backlight at 0x45, own 5 V lead | 2026-10-22 | Gea's first P4 run on the POE-ETH or Module-DEV-KIT; a new DSI controller for the targets (`docs/p4.md`) |
| Waveshare 4.3inch DSI LCD (touch) | MIPI-DSI through a TC358762 bridge to 800x480 RGB, Goodix touch, powered over the ribbon | 2026-10-22 | The Pi case; a P4 experiment only after the 5-inch works (below) |
| LilyGo T-Display S3, T-Deck, T-Embed | SPI ST7789-class panels; the T-Deck's GT911 is composable | earlier | Candidates once the composer has an SPI panel adapter (`docs/kit.md`, "Boards on hand") |
| Arduino shield-type 3.5" (drawer) | Probably 8-bit parallel ILI9486, resistive touch unverified | earlier | The i80 test article when that adapter is written |

Not owned: the Waveshare ESP32-S3-Touch-AMOLED-2.06 (upstream's reference board) and the
ESP32-S3-Touch-LCD-3.49 (assessed below, not bought).

## What the targets tree drives today

Composer (`@geastack/cli`, `custom-target.mjs`) and chip catalog (`core/packages/chips`):
displays `qspi` (co5300, sh8601, rm690b0) and `rgb` only; touch ft3168 and gt911 (ft6336
binding exists, no adapter; cst9217 binding). Hand-written targets add SPI ST7789 (StickS3,
touch-lcd-1.54), SPI ST7796 (P4 touch-lcd-3.5, 80 MHz), MIPI-DSI ILI9881C (P4 Tab5 at
720x1280, P4 touch-lcd-7), e-paper. Gaps a bare panel can fill: a plain SPI adapter in the
composer (track B's shape), an i80 parallel adapter (none anywhere), a resistive or SPI-bus
touch binding (none), any DSI controller beyond ILI9881C, and a P4 composer base.

## The two bought

**XIITIA 3.5" ST7796 SPI module, two for about $15.** 320x480, 8-pin header (GND, VCC, SCL,
SDA, RES, DC, CS, BL) plus an SDO pad, 3.3 V only (no regulator), no touch. The ST7796 itself
speaks SPI and 8/16-bit parallel, but the module is strapped to SPI; the listing's three-bus
claim is the chip's. Breadboards onto any S3 devkit, leaves the octal-PSRAM pins alone, and
the controller's SPI pipeline already exists in the P4 3.5 target, so the composer's SPI
adapter gets two controllers (ST7789 from StickS3, ST7796 from here) under it on both chips.
Role: the display-only pedal on a bare S3, which forces the external foot-controller design
(switches and an encoder on GPIO first; the catalog's TCA9554 and CH422G later). One is a
spare or the P4's SPI panel.

**Waveshare 5-DSI-TOUCH-A.** See the row in `docs/p4.md`. Chosen over the 7-DSI-TOUCH-A for
size; same family (720x1280 IPS, separate 5 V lead, I2C backlight at 0x45, GT9xx touch), with
an HX8394 panel that is new to the tree. The 7 would have matched the Tab5's ILI9881C path
more closely but not the existing 7-inch target's init table, which is for a different panel.

## Passed over, and why

- **Waveshare 4.3inch DSI LCD (800x480, capacitive touch, Pi case bundle; on hand since
  2026-10-22).** Bought for the case. It is "driver
  free" on Pi OS, which means it emulates the official Pi touchscreen: a TC358762 DSI-to-RGB
  bridge plus an MCU at I2C 0x45, powered over the ribbon (about 1.2 W). Not on Waveshare's
  P4 list. One third-party component, `kurozz/esp_lcd_rpi_dsi`, drives that design on the P4
  (verified on Espressif's EV board with an OSOYOO 5-inch clone, IDF 6.1; expects FT5x06 touch
  at 0x38, Waveshare's uses Goodix; the DSI clock lane must stay in high-speed mode). A
  rainy-day experiment after the 5-inch proves the P4 DSI path, and a genuinely different
  display class if it ever works.
- **ILI9341 2.8" SPI + XPT2046 resistive touch.** Would add the first resistive and SPI-bus
  touch binding, and a shoe can press a resistive panel. Deferred: the ST7796 pair covers
  plain SPI.
- **i80 parallel ST7796/ILI9488 3.5" or 4".** The most pedal-relevant bus (480x320 over about
  a dozen pins with no PSRAM-bandwidth fight, the thing that starved the S3 on the 4.3B's RGB
  panel), absent from the composer. The old Arduino shield-type 3.5" panel in a drawer is
  probably an 8-bit parallel ILI9486 and covers this for free when the day comes.
- **Bare COG panels.** Cheaper, but need a 40-pin FPC breakout, a backlight supply and an
  afternoon; nothing in the plan needs one.

## DSI on the Waveshare P4 boards, learned on the way

- The connector is the Pi 4 style 15-pin 1 mm FPC with two DSI lanes, clock, I2C and 3.3 V;
  the P4 boards copied the Pi's pinout, so "Raspberry Pi compatible" on a panel listing is
  the interface claim, not the cable. The POE-ETH box includes the 12 cm cable.
- "Compatible" buys less on the P4 than on a Pi: the Pi kernel and overlay carry the init
  sequence, timings and backlight method; on the P4 the firmware supplies all of it, so a
  panel is only as usable as its documentation. Waveshare publishes ESP-IDF components
  (`waveshare/esp_lcd_ili9881c`, `waveshare/esp_lcd_dsi`, BSPs). Before buying an off-brand
  DSI panel, require: panel IC and resolution, touch IC and address, backlight method, and
  an ESP-IDF example, not just a Pi overlay.
- The DSI-TOUCH-A family does not power over the ribbon: 5 V at 0.5 A or more by a separate
  lead to the header. The older ribbon-powered panels are the bridge-chip ones.
- Waveshare's P4 BSPs list the native-DSI "Raspberry adapter screens" they tested: 2.8, 3.4,
  4, 5, 6.25, 7, 7.9, 8.8, 10.1 and 11.9 inch, generic `esp_lcd_dsi`; the 4.3 is absent.

## The Freenove FNK0104AB, read 2026-11-14

Source: Freenove's `Freenove_ESP32_S3_Display` repository (archive on the LaCie,
`Freenove_ESP32_S3_Display-main.zip`): the 2.8-inch schematic, the TFT_eSPI setup
`FNK0104AB_2.8_240x320_ILI9341.h` and the tutorial sketches' `#else` branches (the `#ifdef`
side is the 3.5-inch FNK0104N). The drawbot project's notes name the same board.

| Function | Pins |
| --- | --- |
| Panel, SPI (HSPI port in the vendor setup) | MOSI 11, SCLK 12, MISO 13, CS 10, DC 46; reset tied to the board reset; backlight 45, high on (BSS138); 40 MHz, BGR, inversion on |
| I2C, shared | SDA 16, SCL 15: FT6336U at 0x38, ES8311 at 0x18 |
| Touch | INT 17, reset 18 (both routed, unlike the LAFVIN carrier) |
| Audio | ES8311: MCLK 4, BCLK 5, WS 7, DOUT 8, DIN 6; SC8002B speaker amp enable 1; LMA2718 analog mic into the codec |
| microSD, SDMMC 4-bit | CLK 38, CMD 40, D0 39, D1 41, D2 48, D3 47 |
| Other | BOOT key 0, WS2812 LED 42, battery ADC 9 (200K/200K divider), TP4054 charger |
| Headers | UART (TXD0, RXD0), expanded IO (21, 14, 3, 2), I2C |

What it means for the pedal:

- **Memory:** 16 MB flash and 8 MB octal PSRAM, the N16R8 the pedal is built for; the LAFVIN
  partition layout fits.
- **USB:** the one USB-C goes to the S3's native port (19/20); there is no UART bridge. The
  pedal's host port for the interface is that same socket, so the console and flashing move to
  the UART header, and the board cannot feed the interface's VBUS: the C port's VBUS reaches
  the board's 5 V through a Schottky (B5819W), not the other way. A Y-cable or powered hub
  supplies the interface, as on any bus-powered-device setup.
- **Footswitch:** BOOT on GPIO 0 is free (the panel's DC is 46, not 0 as on the LAFVIN
  carrier), so the pedal's BOOT-as-footswitch works without lifting a pin; the expanded-IO
  header gives 21, 14, 3 and 2 for real switches.
- **Composer:** the panel needs an ILI9341 path beside track B's ST7789 one (same SPI shape,
  different init sequence; ESP-IDF has an `esp_lcd` ILI9341 component); the FT6336 binding takes
  the routed INT and reset; ES8311 and SDMMC are already composable. The card is SDMMC, not SPI,
  so track G is not needed here.

## The Waveshare ESP32-S3-Touch-LCD-3.49, assessed 2026-10-21

Asked as "does the fork work get Geastack closer to this board?" The answer is yes from two
directions, and the pedal's one real problem on it is the screen's shape, not any driver.
Sources: the Waveshare wiki page, the schematic (`docs/waveshare-349-schematic.pdf`) and the
vendor's ESP-IDF examples (`github.com/waveshareteam/ESP32-S3-Touch-LCD-3.49`, the LVGL
example's `user_config.h` and the audio example's `codec_board/board_cfg.txt`).

**Upstream already drives the panel chip.** The 3.49's panel and touch are one chip, the
AXS15231B over QSPI with touch at I2C address 0x3b. The targets tree drives that chip on two
hand-written boards: `esp32-s3-touch-lcd-3.5b` (Waveshare 3.5B, 320x480, ES8311, SDMMC card,
AXP2101) and `esp32-s3-lilygo-t-display-s3-long` (180x640, software-rotated landscape because
the controller has no usable hardware XY swap, 20 MHz QSPI after corruption at higher clocks).
The 3.49 is the Long's geometry with the 3.5B's peripherals. The AXS15231B is a compile-time
variant of the sh8601 binding (`GEA_EMBEDDED_AXS15231B_PANEL`, `_BACKLIGHT_GPIO`,
`GEA_BOARD_AXS15231B_INIT_HEADER`) and the shared QSPI display layer already knows the chip's
quirks: full-width scanlines, RAMWR priming, serialized colour transactions. The 3.5B's
`touch.cpp` is the 0x3b protocol the 3.49 uses, with the native size as constants.

**The board.** ESP32-S3R8 (8 MB octal PSRAM), 16 MB flash, native USB-C only.

| Role | Pins |
| --- | --- |
| LCD QSPI | CS 9, PCLK 10, D0-D3 11/12/13/14, reset 21, backlight PWM 8 (vendor: SPI3, mode 3, 40 MHz) |
| Touch | own I2C bus, SDA 17 / SCL 18, address 0x3b; INT and reset through the panel FPC |
| System I2C | SDA 47 / SCL 48: TCA9554 at 0x20, PCF85063 at 0x51, QMI8658 at 0x6b, ES8311, ES7210 |
| microSD | SPI, not SDMMC as the wiki says: MOSI 39, MISO 40, CLK 41, CS 38 |
| I2S | MCLK 7, BCLK 15, WS 46, DOUT 45, DIN 6, no PA pin (`pa: -1`), ES7210 is the dual-mic ADC |
| Expander | EXIO1 backlight enable, EXIO6 SYS_EN (power hold), EXIO7 NS_MODE, EXIO4 RTC INT, INT on GPIO 42 |
| Header | 22 pads: 0, 1, 2, 3, 16, 19, 20, 43, 44 and the I2C/UART lines; footswitches and an encoder fit |

**Where the fork tracks land on it.**

- Track G (SPI microSD) is this board's card exactly. Without it a composed 3.49 has no card.
- Track A is not needed: the ES8311 is real, on I2S, so the pedal's codec stopgap goes away
  without a trick.
- Track C's shape (a touch adapter in the chips catalog) is the template for an `axs15231b`
  touch entry: the 3.5B's `touch.cpp` with its native 320x480 made board-defined.
- Tracks H, I, J and K apply unchanged; J's external task stack is the same pattern.
- The 4.3B lesson is the big one. The RGB panel starved internal RAM through PSRAM scanout;
  a QSPI panel with a 172x640x2 = 220 KB framebuffer is the class the pedal was written for
  (the AMOLED 2.06), so the audio-boot RAM fight should not recur.

**What is missing, by size.**

1. A hand-written target: small. Copy the 3.5B directory, swap the pins above, set 172x640
   with the Long's software-landscape defines, start at the Long's 20 MHz and raise toward
   the vendor's 40, take the init table from the vendor's LVGL example, add a
   `build-config.json` entry. A day in the targets fork; the composer is untouched.
2. A composed board: a new track. The composer's QSPI path knows co5300 and sh8601 only and
   cannot emit the AXS15231B define, the backlight GPIO or the init header. It needs an
   `axs15231b` display entry in the chips catalog, an `axs15231b` touch entry, and the
   composer passing their defines through: track B's and C's shape again, one entry each.
3. The pedal's UI does not fit. Its minimum height is 205 logical pixels (`coyopedal/src/ui/README.md`).
   Landscape 640x172 at 1x is 33 rows short and 2x is out of the question; portrait is a
   strip. The 3.5B gets by at 320x213 (1.5x). So the pedal on the 3.49 needs a wide-strip
   layout or shrunk fixed-size controls: coyopedal work, and the real blocker.

**The display alone** is not sold separately and is a bare FPC into the module; the
panel-alone question is answered by the ST7796 module instead.

**Superseded the same evening.** Upstream commit `b9db1ab` (2026-10-21, after the 0.1.107
release) adds `targets/esp32-s3-touch-lcd-3.49` as a hand-written target, with a CLI catalog
entry (`lcd-349`) and `targets.json` buttons (BOOT, PWR on GPIO16). The maintainer has the
board (targets issue #7, opened 2026-10-17 by someone asking for the board or just its
display; he replied "I happen to have that board" on 10-18) and measured it on hardware. So
gap 1 above is closed upstream and no demo-app PR is needed; the composed version (gap 2)
stays open and unasked-for; the pedal UI's height (gap 3) stays the pedal's problem. What
his target does that is worth knowing:

- It is the **V2 board**, from `waveshareteam/ESP32-S3-Touch-LCD-3.49-V2`. The pins in the
  table above came from the V1 repository and schematic, and the two revisions differ:
  V1 has the backlight PWM on GPIO 8, the panel reset on GPIO 21 and the expander INT on
  GPIO 42; V2 swaps those roles (backlight PWM on GPIO 42, active low, gated by EXIO1; panel
  reset on EXIO5; expander INT on GPIO 8, and GPIO 21 is the TE line). QSPI, the two I2C
  buses, I2S, the card (41/39/40) and the launcher button are the same on both. A V1 owner
  would need a variant with those three pins moved, which is the one small contribution
  still open on this board, if anyone turns out to have a V1.
- The card is driven as **SDMMC 1-bit** on 41/39/40, the same three lines the V1 schematic
  labels as SPI; the slot's CS/DAT3 is GPIO 38. Track G is not needed for it.
- Touch is interrupt-driven through the TCA9554's INT (touch INT on EXIO0); the touch bus
  is the AXS15231B's own pair on 17/18, separate from the primary bus.
- Frames go out whole at a paced 30 fps because the glass cannot restart a write at a
  nonzero row; a full frame takes 20 to 25 ms over QSPI at 40 MHz.
- Internal RAM: he moved the runtime onto a PSRAM-stacked task and capped the flush chunk
  at 32 rows so the audio task and Wi-Fi fit, the same fight as our tracks J and K on the
  4.3B, solved one layer up. Worth citing when those tracks go up as PRs.
- One unit reports two fixed phantom contacts under a finger, independent of display
  traffic; he attributes it to that panel.

**Against the ST7796 module (arrived 2026-10-21).** 480x320 landscape at 1.5x gives the same
320x213 logical box the 3.5B uses, so the pedal UI fits it as is; its path into Gea is the
composer's SPI adapter (track B) gaining ST7796 beside ST7789, with the pipeline lifted from
the P4 3.5 target. Order, then: ST7796 on a devkit first (no UI change), a hand-written 3.49
target to prove the AXS15231B path with the counter app, then the composed version as a track.
