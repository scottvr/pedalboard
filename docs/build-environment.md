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
G=../gea-stack/node_modules/@geastack
IDF_TOOLS_PATH=/Volumes/idf6/.espressif-idf6 \
GEA_TARGETS_ROOT=../targets GEA_CHIPS_DIR=../core/packages/chips \
GEA_CORE_DIR=$G/core GEA_HOST_DIR=$G/host GEA_ENGINE_DIR=$G/engine \
GEA_COMPILER_DIR=$G/compiler GEA_ELEMENTS_DIR=$G/elements \
GEA_GEAOS_PACKAGE_DIR=$G/geaos GEA_PLUGIN_DIR=$G/geatsc-plugin-gea \
GEA_PROJECT_BUILD_ROOT=.gea/build-display \
node ../cli/bin/gea.mjs build --board lafvin-display
```

`gea-stack/` is a side install of the framework packages the fork targets expect (core 0.1.40,
host 0.1.15, engine 0.1.16, compiler pinned at exactly 1.0.29 as the forks' lockfiles pin it;
`npm install` there once). The pedal's own `node_modules` stays on its pinned core 0.1.35
stack, which the fork targets cannot build against (their base CMake lists host sources that
0.1.12 lacks), and the pedal's lockfile stays untouched. The compiler must be the locked 1.0.29:
1.0.32 generates a runtime header whose inline declarations collide with the document view
header under GCC 15's `-Werror=attributes`.

The fork CLI needs `npm ci` in `cli/` once. The headless `lafvin` alias keeps building with the
installed packages into `.gea/build`. Two builds never share a build directory; a flash reads
from one too. **`gea flash --no-build` flashes the build directory's own
`gea_embedded.bin`** (CLI 0.1.108, `buildImages()` in `src/esp32/build.mjs`), not
`build/pedalboard.bin`. `build/pedalboard.bin` is only an output copy, and both aliases
overwrite it. Copying a saved image over it does nothing: on 2026-10-23 that is how an
"Oct 14 image" A/B test ended up re-flashing the Oct 23 image (corrected 2026-11-18). A clean build on this Mac is about forty
minutes the first time (every IDF component is compiled; the configure alone is twenty-five on
the spinning disk) and a few minutes after that.

## The 4.3B gift bench

Track F is built apart from the pedal, on upstream's published packages: a worktree of the
targets fork (`targets-4.3b/`), a worktree of core at upstream main (`core-main/`) and a
scaffolded counter app in `tmp/counter-43b/`; the command and the pitfalls (a `node_modules`
inside the targets root hangs the CLI's board resolution) are in `docs/waveshare-43b.md`.

## Saving images

Every build worth flashing again is filed with `tools/save-image.sh <alias> <tag> [build-root]`
right after it is built: the binary, ELF and map land in `images/` under a composite name
(`<alias>-<date>-<pedal commit>-<tag>`) and `images/INDEX.md` gets a row with the four repos'
commits, the framework stack, sizes and SHA-256 prefixes. The files are gitignored, the index
is committed. To flash a saved image, use esptool directly; `gea flash --image` only stages an
OTA slot (it needs `--slot`). With the IDF environment active and the bootloader, partition
table and OTA data from a build of the same alias (any `.gea/build*/…/app-builds/coyopedal/`,
or a copy such as `tmp/flash-display-20261012/`):

```sh
python -m esptool --chip esp32s3 -p /dev/cu.usbmodem… write-flash --flash-mode dio \
  --flash-size 16MB --flash-freq 80m 0x0 bootloader/bootloader.bin \
  0x8000 partition_table/partition-table.bin 0xf000 ota_data_initial.bin \
  0x20000 ../images/<name>.bin
```

The factory models (0x820000) and presets (0x860000) are left as they are. Check the boot log's
`Compile time` line against the image index before trusting any comparison. Overrides when the build was set aside or built on the side stack:
`BIN=`, `SHA=`, `STACK=`, `NOTES=` in the environment.

## The volume itself

`/Volumes/idf6` is an APFS volume inside `/Volumes/LaCie/idf6.sparsebundle` on the LaCie
drive, attached at boot by the root launch daemon
`/Library/LaunchDaemons/com.shared.mountsparsebundle.plist`. When USB is disturbed (a board
taking its port as a host, a replug) the image device can drop and the volume vanishes with
every build on it; `diskutil mount` then fails on the stale device while the bundle is fine.
Recovery: `hdiutil detach disk<N> -force` on the stale device, then `sudo launchctl kickstart
-k system/com.shared.mountsparsebundle`. The Mac's system disk runs full, so builds set
`TMPDIR` to `pedalboard/tmp/tmpdir` and write their logs under `pedalboard/tmp/`.
