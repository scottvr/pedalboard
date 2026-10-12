# Wi-Fi: joining the maintenance network

Paths with no repository prefix are in `coyopedal/`; the forks are named where they are meant.

## Wi-Fi findings (2026-10-11 and 12)

- Symptom on the main network (AT&T gateway, "WPA2/WPA3 Personal" = transition mode, 2.4 GHz
  radio on channel 8 at the time): `auth -> assoc -> run`, four seconds of silence, then
  `reason=15` with a passphrase that was in the image byte for byte. IDF's docs file reason 15
  under wrong password; a transition-mode router meeting a WPA2-with-PMF, no-SAE station
  produces the same thing.
- Cause, two layers: the Gea base target's sdkconfig turns `CONFIG_ESP_WIFI_ENABLE_WPA3_SAE`
  off and this app inherited it; and `remote_service.cpp` set `pmf_cfg.capable = false` against
  a dual-band router that had dropped the handshake the same way, but on the ESP-IDF 6.0.2 the
  README pins that field is deprecated and forced true internally (api-guides/wifi-security).
  The author's workaround never ran on the IDF they documented. Fix: SAE on in the app's
  `sdkconfig.defaults` (layered after the base's), dead assignment removed, comment rewritten
  (`e6dc162`). LAFVIN image 2,358,528 -> 2,405,856 bytes; AMOLED with credentials and SAE
  3,534,144 bytes (56% of its 8 MB slot free). IDF 6 picks WPA3 automatically on a transition
  router once SAE is compiled in.
- The gateway's guest network (2.4 GHz only, a locally-administered BSSID derived from the
  base MAC) refused the pedal at the first authentication frame, `reason=2` after a one-second
  timeout, under WPA2-only and under transition mode, on the right channel. A phone was not
  tried. Not explained; abandoned in favour of the main network, since the guest cannot be
  made WPA2-only without the gateway warning that all bands "must" share one transition-mode
  setting.
- Hidden SSIDs: IDF finds them only on actively scanned channels (1 to 11 with the default
  country policy); the pedal's all-channel scan returned `reason=201` against the hidden guest
  and found it once it was visible. Keep the SSID visible.
- Credentials are compiled in from the gitignored `remote_config.h`; there is no NVS or SD
  override, so a new network means a rebuild. The Wi-Fi driver already persists its station
  config in NVS (`CONFIG_ESP_WIFI_NVS_ENABLED=y`), so runtime provisioning is mostly a
  transport question. Improv Wi-Fi (improv-wifi.com; serial variant over the CH343 port; C++
  parser under Apache-2.0 with an ESP-IDF component manifest; ESP Web Tools flashes and
  provisions from a browser) is the candidate. It does not carry the maintenance API token,
  which is also compiled in: phase one moves only the credentials, the token moves when the
  device can generate one and reveal it once over the same port.
- Tooling found on the way: `gea flash --no-build` and `--image FILE` skip the rebuild (not in
  the help text); the factory asset packers rewrote identical outputs on every run, which made
  every build relink (`29ee4f9` fixes that); the eim installer hard-codes `~/.espressif`, so
  the symlink chain to `/Volumes/idf6` must stay.

## Main network with SAE compiled in (2026-10-12)

- Same gateway, now with SAE in the image and the main SSID in `remote_config.h`: the station
  goes `init -> auth`, sits four seconds, then `auth -> init (0x200)` and the app sees
  `reason=2` (`WIFI_REASON_AUTH_EXPIRE`). Changing the gateway from "WPA2/WPA3 transition" to
  "WPA3 compatible" changed nothing. Before SAE was compiled in the same network got through
  `auth` and `assoc` as a WPA2 station and died at the four-way handshake (reason 15), so the
  failure moved one step earlier: it is the SAE exchange itself that the gateway does not
  complete.
- Hypothesis under test: `remote_service.cpp` left `sae_pwe_h2e` at `WPA3_SAE_PWE_UNSPECIFIED`.
  IDF's header says the default is "both", but in the 6.0.2 supplicant (`esp_wpa3.c`,
  `wpa3_build_sae_commit`) a password element is only derived by hash-to-element when the
  field is `HASH_TO_ELEMENT` or `BOTH`; unspecified sends a hunt-and-peck commit only. A Wi-Fi 6
  gateway that requires H2E can ignore such a commit, which is exactly an auth timeout.
  Diagnostic build: `WPA3_SAE_PWE_BOTH`, plus `CONFIG_ESP_WIFI_DEBUG_PRINT=y` (about 60 KB) so a
  rejected SAE commit logs its status code instead of only reason 2. Remove the debug print
  once the join is understood.
