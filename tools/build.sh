#!/usr/bin/env bash
# Build from the actual project; failed imports or missing outputs fail the build.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
target="${1:-web}"
case "$target" in web|macos|windows|linux|all) ;; *) echo 'usage: tools/build.sh web|macos|windows|linux|all' >&2; exit 2;; esac
version=$("$GODOT" --version)
bash tools/no_sync_duplicates.sh || exit 1
case "$version" in 4.7.2.stable.*) ;; *) echo "Requires Godot 4.7.2 stable; found $version" >&2; exit 2;; esac
mkdir -p build/logs
"$GODOT" --headless --audio-driver Dummy --path game --import > build/logs/import.log 2>&1
if grep -qE '^ERROR:|^SCRIPT ERROR:' build/logs/import.log; then cat build/logs/import.log; exit 1; fi
export_one() {
  local preset="$1" out="$2" label="$3"
  mkdir -p "$(dirname "build/$out")"
  echo "$preset -> build/$out"
  if ! "$GODOT" --headless --audio-driver Dummy --path game --export-release "$preset" "../build/$out" > "build/logs/$label.log" 2>&1; then
    cat "build/logs/$label.log"; return 1
  fi
  if grep -qE '^ERROR:|^SCRIPT ERROR:' "build/logs/$label.log"; then cat "build/logs/$label.log"; return 1; fi
  test -s "build/$out" || { echo "Export output missing: build/$out" >&2; return 1; }
}
case "$target" in
  web) export_one Web web/index.html web;;
  macos) export_one macOS macos/Tato.zip macos;;
  windows) export_one 'Windows Desktop' windows/Tato.exe windows;;
  linux) export_one Linux linux/Tato.x86_64 linux;;
  all)
    export_one Web web/index.html web
    export_one macOS macos/Tato.zip macos
    export_one 'Windows Desktop' windows/Tato.exe windows
    export_one Linux linux/Tato.x86_64 linux;;
esac
echo 'Build complete. Logs: build/logs'
