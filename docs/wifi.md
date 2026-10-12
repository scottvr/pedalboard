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

## Two sniffer captures (2026-10-12, the Mac's built-in radio, channel 9)

Wireless Diagnostics' sniffer on the MacBook Air captures 802.11 frames with radiotap headers;
management frames and the EAPOL frames of the four-way handshake are in the clear even under
WPA3. Files stay in `tmp/` (gitignored). `tshark` from Wireshark.app reads them.

**08:04, gateway in "WPA3 compatible" mode.** The pedal's SAE commit with hash-to-element
(status 126, group 19) is answered in 15 ms; SAE confirm succeeds; association succeeds;
handshake message 1 arrives, the pedal sends message 2, message 3 arrives, and the pedal
itself sends a deauthentication with reason 17, "element in the four-way handshake differs
from the beacon". Ten such rounds in twenty minutes. The gateway's beacon carries a base RSN
element with PSK only and no management-frame protection, plus Wi-Fi Alliance override
elements: RSNE Override (SAE SHA-256, protection required), RSNE Override 2 (GCMP-256,
group-dependent SAE) and an RSNXE Override with hash-to-element. The pedal's association
request selected the override (RSN Selection element) and advertised protection required.
The ESP-IDF 6.0.2 supplicant (`rsn_supp/wpa.c`, under `CONFIG_WPA3_COMPAT`) compares the
override elements it saw in the beacon with the ones in message 3's key data and
deauthenticates on any difference; it logs both as hex at INFO level, which the console
showed only once in the window. It knows the first override and the RSNXE override, not
Override 2.

Between those rounds the pedal logged minutes of `auth -> init`, reason 2: the gateway
ignoring it. Power-cycling the pedal, waiting, and rebooting the gateway did not shorten it.

**11:20, gateway switched to "WPA2/WPA3 transition" (and rebooted earlier).** The beacon has
the same base-plus-override layout as in compatibility mode, so on this gateway both WPA3
settings use the override mechanism. In ninety seconds beside the pedal the sniffer heard only
its probe requests (-18 to -28 dBm), no authentication frame from it and nothing to it, while
the pedal logged `init -> auth` and reason 2 each cycle. The pedal's own frame tap (the
diagnostic image) agreed: nothing received. So in this state the driver enters authentication
but no commit reaches the air. The supplicant declines to build an SAE commit when it cannot
meet its own requirements for the selected variant (the GCMP-256 variant requires
hash-to-element; the override lookup can fail) and says so only at debug level, which the
diagnostic image lacked because the generated sdkconfig is sticky and kept level 3.

**12:xx, compatibility-mode overrides ignored** (`COYOPEDAL_WIFI_NO_WPA3_COMPAT=1`, image
`lafvin-20261012-6cc39f6-wifi-nocompat`). The gateway answers open-system authentication
within 13 ms, status 0, and then retransmits that answer four to six times in forty
milliseconds: it is not receiving the pedal's acknowledgements. The association request
that follows is never answered; after one second the driver reports reason 4
(`ASSOC_EXPIRE`). The pedal hears the gateway at -70 dBm; the laptop beside the pedal hears
the same gateway at -45. This morning's capture showed the same asymmetry from the other
side: every gateway frame retransmitted, every pedal frame carrying the retry flag.

So there were two problems all along. The protocol one is settled: with the override
elements ignored the gateway treats the pedal as a WPA2 client at once, and the flag stays.
The physical one is the blocker: the uplink is too weak for the gateway to hear the pedal
reliably, which explains reason 2 (authentication unheard), reason 15 (handshake frames
unheard), reason 4 (association unheard), the intermittent successes and the "cooldown"
silences. The WROOM module's antenna sits in the carrier's socket beside the display frame,
the battery and the speaker magnets. Next: the same image within a couple of metres of the
gateway in line of sight, then the board out of the carrier; note the RSSI the pedal reports
at each spot against the laptop's -45.

## For the upstream conversation (draft)

The PR that carries the Wi-Fi changes must say this up front, because our commit `e6dc162`
removed the author's comment and its dead assignment, and he should not have to doubt the
change to find out why:

> Your comment on `pmf_cfg.capable` was right about the symptom and close on the mechanism:
> some gateways accept association and then drop the four-way handshake with reason 15
> when the station advertises management-frame protection. A capture on an AT&T gateway
> shows what those routers are: WPA3 compatibility mode, a base RSN element with PSK and no
> protection for legacy clients plus override elements carrying SAE with protection
> required. A station that advertises protection against the base element is neither kind
> of client, and the handshake dies. Your fix stopped advertising it. ESP-IDF 6 deprecates
> that field and forces it true, so the assignment had become a no-op without a warning,
> which is why the fork hit the same reason 15 with the comment still in place. The same
> decision now lives in `disable_wpa3_compatible_mode` (ignore the overrides, join as the
> legacy WPA2 client the base element is there for), with SAE compiled in and
> hash-to-element offered for networks that are WPA3 all the way. The comment is rewritten
> to say so and to keep your observation.

Adjust the last sentences to whichever variant actually joins on the bench.

**First join on the main network (2026-10-12, early afternoon).** Same image, pedal in the
carrier, and a finger resting on the dev board: `security: WPA2-PSK, rssi: -67, pmf:0`,
associated, IP 192.168.1.121 from the gateway. The gateway's block-ack action frame still
needed one retransmission, so the link is marginal rather than fixed, but the protocol side
is closed: with the override elements ignored the pedal is an ordinary WPA2 client to this
gateway. What remains is the antenna: the module in the carrier socket hears the gateway
25 dB worse than the laptop beside it, and a hand on the board changes it. Next: a spare
module in the same carrier, then antenna placement.
