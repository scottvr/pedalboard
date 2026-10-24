# Sources

Kit and vendor code:

- https://lafvin-esp32-s3-multimedia-kit.readthedocs.io/en/latest/ (tutorials; SD, touch,
  battery, camera, I2S pages under `Arduino/`)
- https://github.com/lafvintech/LAFVIN-ESP32-S3-Multimedia-Kit (vendor examples and libraries;
  `lib/TFT_eSPI.zip` holds the display `User_Setup.h`)
- https://www.amazon.com/LAFVIN-Multimedia-Development-Capacitive-Bluetooth/dp/B0H41YD3NN
- https://lafvintech.com/pages/tutorials3

Geastack:

- https://www.npmjs.com/package/@geastack/targets (README: app-local custom targets, chips)
- https://www.npmjs.com/package/@geastack/chips (`catalog.json`)
- https://www.npmjs.com/package/@geastack/cli (`src/boards/custom-target.mjs`,
  `docs/NATIVE-BUILD-CONFIG.md`)

USB and interfaces:

- https://industrialmonitordirect.com/blogs/knowledgebase/resolving-usb-speed-mis-detection-full-vs-high-speed-on-linux
- https://www.embeddedrelated.com/showthread/comp.arch.embedded/213-1.php
- https://userguides.focusrite.com/hc/en-gb/articles/23031328747026-Scarlett-2i2-3rd-Gen-specifications
- https://www.zzounds.com/item--MOT828ES and
  https://vintageking.com/motu-828-mk3-hybrid-firewire-usb-2-0-audio-interface
- https://www.soundonsound.com/reviews/tc-helicon-voicelive-rack and
  https://musictribecommunity.powerappsportals.com/en-us/knowledgebase/article/2018
- https://craiganderton.org/how-to-use-nis-rig-kontrol-3-in-windows-10/
- https://www.manualslib.com/manual/933289/Roland-Gr-55.html?page=66 and
  https://support.roland.com/hc/en-us/articles/115005257466-FA-06-FA-07-FA-08-USB-Driver-Mode

JOYO MOMIX CAB:

- https://www.joyoaudio.co.uk/joyo-momix-cab-guitar-audio-interface-pocket-internal-recording-sound-card
- https://robmurru.wordpress.com/2026/01/24/joyo-momix-cab-reverse-engineering-part-1/
- https://robmurru.wordpress.com/2026/02/24/joyo-momix-cab-reverse-engineering-part-2/
- https://robmurru.wordpress.com/2026/05/31/joyo-momix-cab-reverse-engineering-part-3/
- https://github.com/robmurru/Joyo-MOMIX-CAB-Custom-Firmware (and issues/1)
- JieLi AC6926A4 datasheet: a local copy in `docs/dnd/jieli_ac6926a4.pdf` (the directory is
  gitignored; do-not-distribute material lives there and never reaches a remote)
- https://github.com/kagaimiq/jl-uboot-tool and
  https://github.com/kagaimiq/jl-uboot-tool/blob/main/docs/how-to-enter-uboot.md
- https://kagaimiq.github.io/jielie/chips/chip-marks.html
- https://github.com/christian-kramer/JieLi-AC690X-Familiarization
- https://usmi.mybb.ru/viewtopic.php?id=4 (key patch)
- https://sonicmetric.com/joyo-momix-cab-guitar-audio-interface-review-the-ultimate-mobile-solution-for-guitarists-and-streamers/
- https://www.aliexpress.com/s/wiki-ssr/article/joyo-momix-cab-usb-audio-interface
- https://www.waveshare.com/wiki/ESP32-S3-Touch-LCD-4.3B (schematic: `docs/waveshare-43b-schematic.pdf`, from files.waveshare.com)

Waveshare ESP32-S3-Touch-LCD-3.49 (assessed 2026-10-21, `docs/displays.md`):

- https://www.waveshare.com/wiki/ESP32-S3-Touch-LCD-3.49 (schematic: `docs/waveshare-349-schematic.pdf`, from waveshare.net)
- https://github.com/waveshareteam/ESP32-S3-Touch-LCD-3.49 (`Examples/ESP-IDF/09_LVGL_V8_Test/main/user_config.h` for the LCD and touch pins,
  `08_Audio_Test/components/codec_board/board_cfg.txt` for the I2S pins)
