# The LAFVIN ESP32-S3 Multimedia Kit

Paths with no repository prefix are in `coyopedal/`; the forks are named where they are meant.

## The kit, as shipped

- LAFVIN ESP32-S3 Multimedia Kit: a carrier board with a socketed ESP32-S3-WROOM-1 N16R8 dev
  board (16 MB flash, 8 MB octal PSRAM). The dev board has its own USB-OTG and USB-UART
  (CH343) USB-C ports, a BOOT button and the camera FPC connector.
- Carrier peripherals: 2.8" 240 x 320 SPI LCD module (vendor docs say ILI9341V, the shipped
  TFT_eSPI setup uses the ST7789 driver with BGR order at 80 MHz; the module header is
  MOSI SCK CS DC BL RST INT SDA SCL VCC GND), FT6336U capacitive touch, MAX3010x heart-rate
  sensor, microSD on SDMMC 1-bit, an audio module with a PCM5100 I2S DAC and a PAM8403 class-D
  amplifier (header SCK BCK DIN LCK VCC GND; no I2C, no codec registers; the vendor code treats
  it like a MAX98357A), stereo speakers, WS2812 LED, buzzer, 6 to 12 V DC jack with power
  switch. The heart-rate sensor, the audio module and the camera are all removable or
  ignorable for the pedal.
- Programming is through the CH343 UART port. The vendor's own examples use GPIO 19 and 20 as
  ordinary GPIOs, which is why the native USB port is unusable while the dev board is seated.

### Pin map (carrier silkscreen, confirmed by the vendor code)

The silkscreen table itself, in the socket's physical order, is in "Carrier pinout" below; this is the same
information grouped by function.

| Function                  | GPIOs                                                                           |
| ------------------------- | ------------------------------------------------------------------------------- |
| LCD SPI                   | MOSI 20, SCK 21, CS 47, DC 0                                                    |
| Touch, heart-rate I2C     | SCL 1, SDA 2                                                                    |
| microSD (SDMMC 1-bit)     | CLK 39, CMD 38, D0 40                                                           |
| I2S DAC/amp               | BCK 42, LCK 14, DIN 41                                                          |
| Camera (on the dev board) | SIOD 4, SIOC 5, VSYNC 6, HREF 7, XCLK 15, PCLK 13, Y2-Y9 11 9 8 10 12 18 17 16  |
| Other                     | WS2812 48, buzzer 45, ADC_BAT 19, UART 43/44, PSRAM 35-37                       |
| Free                      | 3 and 46 (strapping pins, normal I/O); camera pins when the ribbon is unplugged |

The ESP32-S3 has no input-only GPIOs (checked in ESP-IDF 5.5.4 `soc_caps.h`), so 3 and 46 are
valid outputs.

### Why the native USB matters

The pedal takes audio in and out through a USB Audio Class interface on the S3's native
USB-OTG controller, which only exists on GPIO 19 (D-) and 20 (D+). On the carrier those pins
are ADC_BAT and TFT_MOSI, and GPIO 0 (BOOT, the pedal's footswitch) is TFT_DC.

### Planned hardware mod

1. Lift dev-board pins 19 and 20 out of the carrier socket (bend, do not cut carrier traces,
   so no stubs stay on the USB data lines). The battery ADC is lost; the pedal never reads it.
2. Lift pin 0 as well, so the BOOT button stays the pedal's footswitch (hard-coded as GPIO 0 in
   `src/native/main/main.cpp`, with an interrupt input, and the touch UI has no bypass control).
3. Jumper the display module's MOSI and DC pads to free dev-board header pins (GPIO 3 and 46,
   or camera pins with the ribbon unplugged). The panel already runs through the GPIO matrix,
   so any free pin works.
4. USB: the dev board's OTG port. Measured 2026-10-10: with the board powered from the UART
   port, the OTG port carries 5 V out (the MOMIX lights up in it), and each port alone puts a
   steady 5 V on the header's 5 V pin, so no IN/OUT jumper work is needed. The fallback is to
   wire the interface's D+, D-, 5 V and GND straight to the header at GPIO 20, GPIO 19, 5 V
   and GND. The MOMIX draws 50 mA.
5. Power the kit from the DC jack so display and LED switching noise stays off the rail that
   feeds the interface's preamp.

### Carrier pinout

Transcribed from the silkscreen table on the back of the carrier board (photo `photos/IMG_4706.jpeg`; `IMG_4707.jpeg` is the board layout). The rows follow the silkscreen top to bottom, left column then right column,
which is the physical order of the dev-board socket. Every assignment agrees with the vendor's
example code.

| Left pin | Left function | Right pin | Right function |
| -------- | ------------- | --------- | -------------- |
| 3V3      |               | GPIO43    | Serial_TX      |
| EN       | RST           | GPIO44    | Serial_RX      |
| GPIO4    | Cam_SIOD      | GPIO1     | IIC_SCL        |
| GPIO5    | Cam_SIOC      | GPIO2     | IIC_SDA        |
| GPIO6    | Cam_VSYNC     | GPIO42    | IIS_BCK        |
| GPIO7    | Cam_HREF      | GPIO41    | IIS_DIN        |
| GPIO15   | Cam_XCLK      | GPIO40    | SD_DATA        |
| GPIO16   | Cam_Y9        | GPIO39    | SD_CLK         |
| GPIO17   | Cam_Y8        | GPIO38    | SD_CMD         |
| GPIO18   | Cam_Y7        | GPIO37    | PSRAM          |
| GPIO8    | Cam_Y4        | GPIO36    | PSRAM          |
| GPIO3    | Strapping     | GPIO35    | PSRAM          |
| GPIO46   | Strapping     | GPIO0     | TFT_DC         |
| GPIO9    | Cam_Y3        | GPIO45    | Strapping      |
| GPIO10   | Cam_Y5        | GPIO48    | WS2812         |
| GPIO11   | Cam_Y2        | GPIO47    | TFT_CS         |
| GPIO12   | Cam_Y6        | GPIO21    | TFT_SCK        |
| GPIO13   | Cam_PCLK      | GPIO20    | TFT_MOSI       |
| GPIO14   | IIS_LCK       | GPIO19    | ADC_BAT        |
| 5V       |               | GND       |                |

Reading notes:

- The silkscreen prints `Cam_HERF` for the camera's HREF line and `Stropping` once for
  `Strapping`; both are corrected above.
- Camera data lines map to the sensor as Y2 to Y9 = D0 to D7, so D0 is GPIO11, D1 GPIO9, D2
  GPIO8, D3 GPIO10, D4 GPIO12, D5 GPIO18, D6 GPIO17, D7 GPIO16.
- `IIS_DIN` is the audio module's data input, driven by the ESP32-S3; `IIS_BCK` and `IIS_LCK`
  are its bit and word clocks. The module is a PCM5100 DAC with a PAM8403 amplifier, with no
  I2C.
- `IIC` carries the FT6336U touch controller and the MAX3010x heart-rate sensor.
- GPIO19 and GPIO20 are the ESP32-S3's native USB pins (D- and D+). On this carrier they are
  the battery divider and the display's MOSI, which is why the dev board's OTG port cannot host
  a USB interface until those two pins are lifted out of the socket. GPIO0 is both the BOOT
  button, the pedal's footswitch, and the display's D/C line. The plan for all three is "Planned hardware mod" above.
- Free pins with the camera ribbon unplugged: GPIO3 and GPIO46 always; GPIO4 to GPIO13 and
  GPIO15 to GPIO18 then become free as well.

Flash: the kit's dev board carries a Boya flash part. The pedal's sdkconfig keeps the Boya
chip driver off on purpose (every chip driver's functions sit in IRAM, which costs DRAM on
the S3; the AMOLED board has a GigaDevice part), so the boot log warns "Detected boya flash
chip but using generic driver". The generic driver runs it at 80 MHz QIO; the chip driver
would only add suspend support, and auto-suspend is out because it forces ~25 KiB of
system code into IRAM. Expected, not a fault.

## Boards on hand (2026-10-09)

"AMOLED" in the pedal's docs means the Waveshare ESP32-S3-Touch-AMOLED-2.06, the upstream
reference board (alias `amoled`), which we do not have. Our test vehicle is the kit's own dev
board running the headless `lafvin` composed target (the generic `s3-devkit` target cannot
build for this app until Geastack gates its ES8311 binding; see `geastack.md`, "What is missing upstream"):

- **Development vehicle: an ESP32-S3-WROOM-1 N16R8 dev board**, the kit's own or a spare,
  flashed with the `lafvin` target. Either one of the spare
  N16R8 boards, or the LAFVIN kit's own dev board pulled out of its carrier socket, which is
  reversible and frees its OTG port with no mod at all. Console and flashing go through the
  CH343 UART port; the pedal is configured over the maintenance API (Wi-Fi credentials via
  `npm run remote:configure`). It needs 8 MB PSRAM, so only R8 modules qualify; the bare
  WROOM-1 modules in the drawer count only if they are N16R8 and sit on a carrier with USB.
- **VBUS on the devkit:** the kit's own dev board does feed its OTG port when powered from
  the UART port (measured 2026-10-10, MOMIX powers up in it). A spare board may not; check it
  the same way before reaching for a Y-cable or powered hub. The MOMIX needs 50 mA.
- **Freenove ESP32-S3 (in the drawing robot):** leave it there. If it is the N8R8 variant its
  8 MB flash would need its own partition layout anyway.
- **LilyGo T-Deck, T-Embed, T-Display S3:** all ST7789-class panels, so they share the LAFVIN
  kit's Geastack gap (no SPI panel in the composable base). The T-Deck's GT911 touch is already
  composable, so it becomes a candidate once an SPI panel driver exists upstream. Only the
  T-Display S3 Long has a ready Geastack target. The T-Dongle-S3 is a USB plug, not a host
  port; unsuitable.
- Staging that keeps the fun: stage 1 is the kit's dev board alone as `s3-devkit` for the
  UAC1 and MOMIX work; stage 2 is the carrier mod and the composed target.
