# Saved firmware images

Binaries, ELFs and maps are gitignored; this index is the record. SHA-256 columns are the first 16 hex digits. A `+` after the pedal commit means the tree was dirty.

| Image | Alias | Pedal | Forks (cli targets core) | Stack (pedal node_modules unless noted) | Size | bin SHA-256 | elf SHA-256 | Notes |
| ----- | ----- | ----- | ------------------------ | --------------------------------------- | ---: | ----------- | ----------- | ----- |
| `lafvin-display-20261012-fa703b1-first-link` | lafvin-display | fa703b1 | cli 5aea1d9 targets d107bfb core 14f08ad | side stack: core 0.1.40 host 0.1.15 engine 0.1.16 compiler 1.0.29 | 3486272 | `d172d1255f42d110` | `1dd38119d483e830` | first link of the display variant against the forks (cli 5aea1d9, targets d107bfb, core 14f08ad); not flashed, hardware mod pending |
