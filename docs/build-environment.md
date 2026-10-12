# Build environment and bench workflow

Paths with no repository prefix are in `coyopedal/`; the forks are named where they are meant.

## Build environment on this Mac (2026-10-09)

- Intel Mac; Homebrew in `/usr/local`, MacPorts in `/opt/local` (the user is moving to
  MacPorts; `/opt/homebrew` is a symlink to `/opt/local`). Python for host scripts is the
  python.org 3.14 venv at `~/.venv` (pyusb, pyserial). `DYLD_FALLBACK_LIBRARY_PATH`, if set,
  must repeat dyld's defaults (`~/lib:/usr/local/lib:/usr/lib`) or Homebrew libraries vanish.
- ESP-IDF 6.0.2 lives on the APFS sparse bundle `/Volumes/idf6`: tree at
  `/Volumes/idf6/esp/esp-idf` (also reachable as `~/esp/esp-idf`), tools root
  `/Volumes/idf6/.espressif-idf6`. The CLI finds the tree by itself but needs
  `IDF_TOOLS_PATH=/Volumes/idf6/.espressif-idf6` exported; `~/.zshrc` sets it. `install.sh
esp32s3` leaves out `riscv32-esp-elf-gdb`, which `idf_tools.py export` demands, so
  `idf_tools.py install riscv32-esp-elf-gdb` is part of setup. Keep IDF trees and `.gea/build`
  off the boot volume; it filled up once. The repositories moved to `/Volumes/idf6/pedalboard/` on 2026-10-12 (this
  repository is that directory); the CMake caches were discarded with the move.
- Format tooling: `npm run format:setup` installs clang-format 22.1.8, ruff and cmake-format
  into `build/format-tools`; `npm run format:check` fails loudly if that venv is missing.
- Machine-local aliases in the gitignored `.gea/boards.json`: `amoled` (build only),
  `s3-devkit` (build only, currently fails upstream), `lafvin` (needs `transports.usbSerial.serial`
  from `npx gea boards discover` before flashing). `npx gea flash --board lafvin --monitor`
  provisions over the CH343 port; a board already in maintenance mode updates over Wi-Fi with
  `tools/esp32/amoled_remote.py ota`.

## Building the display variant against the forks

The three Geastack forks are cloned beside `coyopedal/` (`cli/`, `targets/`, `core/` with
`packages/chips`), each on branch `lafvin-composed-display`. The pedal consumes them without
touching its `package.json` dependencies (its coyopedal's `skills/updating-gea-dependencies` forbids
`file:` dependencies and patched `node_modules`): the board variant
`boards/esp32-s3-lafvin-multimedia-2.8-display.json` (alias `lafvin-display` in the gitignored
`.gea/boards.json`) is built with the fork CLI and the package-path overrides the CLI already
honours, into its own build root so the bench `lafvin` build is untouched:

```sh
cd coyopedal
IDF_TOOLS_PATH=/Volumes/idf6/.espressif-idf6 \
GEA_TARGETS_ROOT=../targets GEA_CHIPS_DIR=../core/packages/chips \
GEA_PROJECT_BUILD_ROOT=.gea/build-display \
node ../cli/bin/gea.mjs build --board lafvin-display
```

The fork CLI needs `npm ci` in `cli/` once. The headless `lafvin` alias keeps building with the
installed packages into `.gea/build`. Two builds never share a build directory; a flash reads
from one too. A clean build on this Mac is about forty minutes the first time (every IDF
component is compiled) and a few minutes after that.
