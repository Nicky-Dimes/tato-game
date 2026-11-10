#!/usr/bin/env bash
# Builds release exports into build/.   Usage: tools/build.sh web|macos|windows|linux|all
# Needs Godot 4.7.2 on the PATH as `godot` (or set GODOT=/path/to/godot) with export templates.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
target="${1:-web}"

"$GODOT" --headless --path game --import >/dev/null 2>&1 || true

export_one() {
  local preset="$1" out="$2"
  mkdir -p "$(dirname "build/$out")"
  echo "== $preset -> build/$out"
  "$GODOT" --headless --path game --export-release "$preset" "../build/$out"
  test -s "build/$out" || { echo "export failed: build/$out is missing"; exit 1; }
}

case "$target" in
  web) export_one "Web" "web/index.html" ;;
  macos) export_one "macOS" "macos/Tato.zip" ;;
  windows) export_one "Windows Desktop" "windows/Tato.exe" ;;
  linux) export_one "Linux" "linux/Tato.x86_64" ;;
  all)
    export_one "Web" "web/index.html"
    export_one "macOS" "macos/Tato.zip"
    export_one "Windows Desktop" "windows/Tato.exe"
    export_one "Linux" "linux/Tato.x86_64"
    ;;
  *) echo "usage: tools/build.sh web|macos|windows|linux|all"; exit 2 ;;
esac
echo "done"
