#!/bin/sh
# Save a built firmware image under images/ with a composite name and an index row.
#
#   tools/save-image.sh <alias> <tag> [build-root]
#
# <alias> is the .gea/boards.json alias the image was built for (lafvin,
# lafvin-display); <tag> says why it exists (wifi-diag, first-link, release).
# [build-root] defaults to coyopedal/.gea/build; the display variant builds into
# coyopedal/.gea/build-display. The binary is taken from coyopedal/build/pedalboard.bin,
# which every alias writes, so save right after the build that produced it.
# Environment overrides: BIN=<binary> when it was set aside under another name,
# SHA=<pedal commit> when the tree has moved on since the build, STACK="<text>"
# when the image was built on the side stack (gea-stack/) rather than the
# pedal's node_modules, NOTES="<text>" for the index row.
set -eu
alias="${1:?alias}"; tag="${2:?tag}"
here="$(cd "$(dirname "$0")/.." && pwd)"
pedal="$here/coyopedal"
root="${3:-$pedal/.gea/build}"
case "$alias" in
  lafvin) target=esp32-s3-lafvin-multimedia-2.8 ;;
  lafvin-display) target=esp32-s3-lafvin-multimedia-2.8-display ;;
  *) target="$alias" ;;
esac
app="$root/$target/app-builds/nam-pedalboard"
bin="${BIN:-$pedal/build/pedalboard.bin}"
elf="$app/gea_embedded.elf"
map="$app/gea_embedded.map"
[ -f "$bin" ] || { echo "no $bin" >&2; exit 1; }
[ -f "$elf" ] || { echo "no $elf" >&2; exit 1; }
date="$(date +%Y%m%d)"
sha="${SHA:-$(git -C "$pedal" rev-parse --short HEAD)}"
dirty=""; [ -n "${SHA:-}" ] || [ -z "$(git -C "$pedal" status --porcelain --untracked-files=no)" ] || dirty="+"
stem="$alias-$date-$sha$dirty-$tag"
out="$here/images"
cp "$bin" "$out/$stem.bin"; cp "$elf" "$out/$stem.elf"; [ -f "$map" ] && cp "$map" "$out/$stem.map"
binsha="$(shasum -a 256 "$out/$stem.bin" | cut -c1-16)"
elfsha="$(shasum -a 256 "$out/$stem.elf" | cut -c1-16)"
size="$(stat -f %z "$out/$stem.bin")"
forks=""
for r in cli targets core; do
  forks="$forks $r $(git -C "$here/$r" rev-parse --short HEAD)"
done
stack="${STACK:-}"
[ -n "$stack" ] || for p in core host engine compiler; do
  v="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$pedal/node_modules/@geastack/$p/package.json")"
  stack="$stack $p $v"
done
[ -f "$here/images/INDEX.md" ] || printf '# Saved firmware images\n\nBinaries, ELFs and maps are gitignored; this index is the record. SHA-256 columns are the first 16 hex digits. A `+` after the pedal commit means the tree was dirty.\n\n| Image | Alias | Pedal | Forks (cli targets core) | Stack (pedal node_modules unless noted) | Size | bin SHA-256 | elf SHA-256 | Notes |\n| ----- | ----- | ----- | ------------------------ | --------------------------------------- | ---: | ----------- | ----------- | ----- |\n' > "$here/images/INDEX.md"
printf '| `%s` | %s | %s%s |%s |%s | %s | `%s` | `%s` | %s |\n' "$stem" "$alias" "$sha" "$dirty" "$forks" "$stack" "$size" "$binsha" "$elfsha" "${NOTES:-}" >> "$here/images/INDEX.md"
echo "saved images/$stem.bin ($size bytes), .elf, .map; index row appended"
