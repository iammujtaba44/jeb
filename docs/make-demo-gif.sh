#!/usr/bin/env bash
#
# Builds docs/demo.gif from the PNG screenshots in docs/screenshots/,
# in filename order, using ffmpeg with a generated palette for clean colors.
#
# Usage:  ./scripts/make-demo-gif.sh
#
set -euo pipefail

cd "$(dirname "$0")/.."

SHOTS_DIR="docs/screenshots"
OUT="docs/demo.gif"
SECONDS_PER_FRAME="2"   # how long each screenshot is shown
WIDTH="300"             # output width in px (height scales automatically)

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "error: ffmpeg is required (brew install ffmpeg)" >&2
  exit 1
fi

shopt -s nullglob
shots=("$SHOTS_DIR"/*.png)
if [ ${#shots[@]} -eq 0 ]; then
  echo "error: no PNGs found in $SHOTS_DIR — add screenshots first" >&2
  exit 1
fi

framerate="$(awk "BEGIN { print 1 / $SECONDS_PER_FRAME }")"
palette="$(mktemp -t jeb-palette).png"
trap 'rm -f "$palette"' EXIT

echo "Building $OUT from ${#shots[@]} screenshots…"

ffmpeg -y -framerate "$framerate" -pattern_type glob -i "$SHOTS_DIR/*.png" \
  -vf "scale=${WIDTH}:-1:flags=lanczos,palettegen=stats_mode=diff" \
  "$palette" >/dev/null 2>&1

ffmpeg -y -framerate "$framerate" -pattern_type glob -i "$SHOTS_DIR/*.png" \
  -i "$palette" \
  -lavfi "scale=${WIDTH}:-1:flags=lanczos[x];[x][1:v]paletteuse" \
  -loop 0 "$OUT" >/dev/null 2>&1

echo "Wrote $OUT"
