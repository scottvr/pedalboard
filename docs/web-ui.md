# A browser UI for maintenance mode

Captured 2026-10-16 from a conversation; nothing is built. Picks up as its own feature branch
of the pedal fork, developed against a headless S3 (the bare module or the kit's dev board
out of the carrier), because that is the configuration with no other way in; the boards with
panels get it for free, since maintenance mode is the same on all of them.

## What exists

- Maintenance mode runs an HTTP server on port 8080 (`src/native/services/remote_service.cpp`)
  with a compiled-in token checked on every request (`X-CoyoPedal-Token`, 32+ characters,
  `remote_config.h`). Endpoints: `/v1/status` (JSON), `/v1/screen` (the live framebuffer),
  `/v1/logs`, `/v1/command` (text verbs: `PRESET <index>`, `MODEL <index>`, `EFFECT MASK
  <0..63>`, `UI SCREEN <0..10>`, `AUDIO MODE`, the profile and soak windows, `REBOOT`, `HELP`
  lists them), `/v1/ota`, model import and download, IR upload, download and list.
  `tools/esp32/amoled_remote.py` is a thin client over these; it is the only client today.
- The pedal serves no HTML. Nothing in the firmware is a web page.
- The touchscreen UI is TSX with one CSS file per component (`src/ui/components/*.css`,
  about 15 KB in all, the shared shell in `App.css`) and the font
  `assets/fonts/Saira-Bold-Pedal.otf` (22 KB, the UI's icons drawn in as glyphs). The same
  source builds two ways: the Gea compiler turns it into native C++ on the device (no
  JavaScript runtime there), and Vite builds it against the Gea web runtime for the browser
  preview (`src/preview/`, a simulated pedal from `board-fixture.mjs`). The boundary between
  the two is `src/ui/board.ts`: numeric getters, labels and a handful of actions, backed on
  the device by `src/native/ui/board_bridge.cpp` and in the browser by the fixture.
- Audio mode has both radios off; only maintenance mode answers the network. That is
  upstream's design (timing and RAM), so any browser UI configures the pedal between playing,
  as the Python tool does. On a headless pedal the API is the only way in, and a page makes
  that path usable without installing Python.

## The idea, in three sizes

1. **A plain page.** One static HTML file embedded in the firmware and served by the existing
   server; fetch calls to the existing endpoints; the token typed once and kept in the
   browser. Presets, models, effects on and off, status, logs, OTA. About a day. The Python
   tool keeps working beside it.
2. **The plain page in the pedal's clothes.** The same page, but its markup uses the
   component stylesheets' class names and loads the pedal's own CSS and font, served from the
   firmware too (roughly 40 KB of assets). Looks like the pedal, costs about what 1 costs,
   adds no new surface to the firmware's state model. This is the one to build first: a
   cohesive product rather than a tech novelty, and a stepping stone to 3. Its risk is drift:
   a page that borrows class names falls behind when a component's CSS changes, so it wants a
   test that every class the page uses exists in the stylesheets it loads.
3. **The real UI in the browser.** The TSX unchanged, with a second board adapter that answers
   `board.ts` from a batched state endpoint and sends actions to the command endpoint; the
   pedal serves the Vite bundle. The Wasm demo shows the web runtime running the compiled app
   in a browser, which is why this is possible, and why it is more than glue: the web runtime
   expects to own the board boundary, the boundary is polled getter by getter for an
   in-process bridge, and parameter edits today go only through the native bridge. Needs a
   `/v1/state` JSON endpoint and a write path. About a week, with upstream's blessing.

## Order of work, when it starts

- Design note to the maintainer first, framed around the headless build (already an upstream
  configuration: "the same firmware builds for a bare module with no panel"). Ask before
  building; the page's verbs are upstream's API.
- Branch off the fork, built and tested against the headless kit alias (`lafvin`, out of the
  carrier) or `s3-devkit`. Serve `/` from the existing httpd with the page embedded through
  `gea.targets.esp32.embedFiles` in `package.json`; the token goes in a header from the page,
  same origin so no CORS.
- Size 2 straight away, not size 1 then 2: the markup borrowing the stylesheets is the whole
  difference, and it is cheap on day one.
- Then the measurement of what the page costs: flash (tens of KB), heap while serving (the
  httpd already exists; one more handler), nothing in audio mode.
- Size 3 only if the maintainer wants the TSX to be the single UI source for the browser
  too; it depends on the state endpoint and on how the Gea web runtime's board boundary is
  meant to be driven, both questions for him.

Related: Improv Wi-Fi provisioning (`docs/wifi.md`) is the other half of "no Python needed":
credentials over serial, then the page over Wi-Fi.
