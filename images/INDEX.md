# Saved firmware images

Binaries, ELFs and maps are gitignored; this index is the record. SHA-256 columns are the first 16 hex digits. A `+` after the pedal commit means the tree was dirty.

| Image | Alias | Pedal | Forks (cli targets core) | Stack (pedal node_modules unless noted) | Size | bin SHA-256 | elf SHA-256 | Notes |
| ----- | ----- | ----- | ------------------------ | --------------------------------------- | ---: | ----------- | ----------- | ----- |
| `lafvin-display-20261012-fa703b1-first-link` | lafvin-display | fa703b1 | cli 5aea1d9 targets d107bfb core 14f08ad | side stack: core 0.1.40 host 0.1.15 engine 0.1.16 compiler 1.0.29 | 3486272 | `d172d1255f42d110` | `1dd38119d483e830` | first link of the display variant against the forks (cli 5aea1d9, targets d107bfb, core 14f08ad); not flashed, hardware mod pending |
| `lafvin-20261012-fa08339-wifi-diag` | lafvin | fa08339 | cli 5aea1d9 targets d107bfb core 14f08ad | core 0.1.35 host 0.1.12 engine 0.1.10 compiler 1.0.20 | 2429872 | `ea623137c8277901` | `516361aaea583ec3` | diagnostic image for the main-network join: frame tap, scan report, supplicant debug, reconnect backoff; sdkconfig at DEBUG max level with supplicant debug print |
| `lafvin-20261012-6cc39f6-wifi-nocompat` | lafvin | 6cc39f6 | cli 5aea1d9 targets d107bfb core 14f08ad | core 0.1.35 host 0.1.12 engine 0.1.10 compiler 1.0.20 | 2429888 | `8d93b48a2c5a8063` | `156048fc856af101` | compatibility-mode opt-out on top of the diagnostic image; joins as a legacy WPA2 client |
