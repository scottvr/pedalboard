# Pedalboard workspace

One volume, one directory, every repository the ESP32-S3 NAM pedal work touches. Launch
Claude Code from this directory so the whole set is in scope.

| Directory    | What it is                                                         | Upstream                    |
| ------------ | ------------------------------------------------------------------ | --------------------------- |
| `coyopedal/` | The pedal firmware fork (branch `lavfin-kit-notes`)                | the original author's repo  |
| `cli/`       | Fork of `@geastack/cli` (`gea` CLI, the custom-target composer)    | github.com/geastack/cli     |
| `targets/`   | Fork of `@geastack/targets` (board sources, ESP32 bindings)        | github.com/geastack/targets |
| `core/`      | Fork of `@geastack/core` (`packages/chips` holds the chip catalog) | github.com/geastack/core    |

Forks live under github.com/scottvr; clone them here with `gh repo clone scottvr/<name>`,
which adds the `upstream` remote. Branch per upstream track; never patch `node_modules`.

This directory is itself a repository: the project's notes (`README.md` "Status", `docs/`) and
working list (`BACKLOG.md`: "Current sprint", "Upstream tracks") live here, in prose, and the
four code repositories are gitignored siblings. Start a session with "Status" and "Current
sprint"; end it by moving finished items to "Done" and writing what was learned into the topic
file under `docs/`. **Read `coyopedal/AGENTS.md` first** for anything in the pedal repo.

Build environment: ESP-IDF 6.0.2 at `/Volumes/idf6/esp/esp-idf` (also `~/esp/esp-idf`), tools
at `/Volumes/idf6/.espressif-idf6`; export `IDF_TOOLS_PATH=/Volumes/idf6/.espressif-idf6` on
every build command. Python packages go in `~/.venv` (python.org 3.14) or the IDF env.

Flash the LAFVIN board from the pedal repo with
`npx gea flash --board lafvin --no-build --monitor` after `npx gea build --board lafvin`;
one build per build directory at a time. Don't flash hardware unless asked.
