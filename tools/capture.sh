#!/usr/bin/env bash
# Actual Godot renderer capture. Usage: tools/capture.sh W1-L1 output.png [debug flags]
# Linux: install Xvfb or set XVFB=/path/to/Xvfb. Uses existing DISPLAY when supplied.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
stage="${1:-W1-L1}"
output="${2:-qa/gameplay.png}"
if [ "$#" -ge 2 ]; then shift 2; else set --; fi
mkdir -p "$(dirname "$output")"
output="$(cd "$(dirname "$output")" && pwd)/$(basename "$output")"
scratch=$(mktemp -d "${TMPDIR:-/tmp}/tato-capture.XXXXXX")
export XDG_DATA_HOME="$scratch/data"
export XDG_CONFIG_HOME="$scratch/config"
export XDG_CACHE_HOME="${TATO_RENDER_CACHE:-$scratch/cache}"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
server_pid=''
cleanup() { if [ -n "$server_pid" ]; then kill "$server_pid" 2>/dev/null || true; fi; }
trap cleanup EXIT
if [ -z "${DISPLAY:-}" ]; then
  XVFB="${XVFB:-Xvfb}"
  "$XVFB" -displayfd 3 -screen 0 1280x720x24 -nolisten tcp -ac -extension MIT-SHM 3>"$scratch/display" >"$scratch/xvfb.log" 2>&1 &
  server_pid=$!
  for _ in {1..50}; do [ -s "$scratch/display" ] && break; kill -0 "$server_pid"; sleep 0.1; done
  [ -s "$scratch/display" ] || { cat "$scratch/xvfb.log"; exit 1; }
  export DISPLAY=":$(cat "$scratch/display")"
fi
export LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-1}"
movie_args=()
if [ -n "${TATO_MOVIE:-}" ]; then movie_args=(--write-movie "$TATO_MOVIE" --fixed-fps 30); fi
"$GODOT" "${movie_args[@]}" --path game --audio-driver Dummy --rendering-driver opengl3 --disable-vsync -- \
  "--level=$stage" "--shot=$output" --shot-after=240 --shot-count=1 "$@" >"$output.log" 2>&1
test -s "$output"
if grep -q '^SCRIPT ERROR:' "$output.log"; then cat "$output.log"; exit 1; fi
printf 'Captured actual Godot stage %s: %s\n' "$stage" "$output"
