#!/usr/bin/env bash
# Reproducible checks with isolated saves, exact engine validation and retained logs.
# Usage: tools/check.sh [all|quick|unit|integration|smoke]
set -uo pipefail
cd "$(dirname "$0")/.."
mode="${1:-all}"
case "$mode" in all|quick|unit|integration|smoke) ;; *) echo "Unknown check mode: $mode" >&2; exit 2;; esac
GODOT="${GODOT:-godot}"
version=$("$GODOT" --version 2>/dev/null) || { echo 'Godot missing; set GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64' >&2; exit 2; }
case "$version" in 4.7.2.stable.*) ;; *) echo "Requires Godot 4.7.2 stable; found $version" >&2; exit 2;; esac
log="${TATO_QA_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/tato-qa.XXXXXX")}"
mkdir -p "$log"
log=$(cd "$log" && pwd)
# Never touch a developer's actual game saves/settings during tests.
export XDG_DATA_HOME="$log/runtime/data"
export XDG_CONFIG_HOME="$log/runtime/config"
export XDG_CACHE_HOME="$log/runtime/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
failed=0
run_engine() {
  if command -v timeout >/dev/null; then timeout "${TATO_CHECK_TIMEOUT:-240}" "$GODOT" "$@";
  else "$GODOT" "$@"; fi
}
step() {
  local name="$1"; shift
  echo "$name"
  if run_engine --headless --audio-driver Dummy --path game "$@" > "$log/$name.log" 2>&1; then :
  else echo "  Command failed; see $log/$name.log"; failed=1; fi
  if grep -qE '^SCRIPT ERROR:|Parse Error:' "$log/$name.log"; then
    echo '  Unexpected script error'; failed=1
  fi
}
bash tools/no_sync_duplicates.sh || exit 1
echo "Godot: $version"
if ! python3 tools/validate_art.py > "$log/art.log" 2>&1; then failed=1; fi
cat "$log/art.log"
echo "Logs: $log"
step import --import
if grep -q '^ERROR:' "$log/import.log"; then failed=1; fi
step resources res://tools/CheckScripts.tscn
grep -E 'checked [0-9]+ files' "$log/resources.log" || true
grep -q '0 problem(s)' "$log/resources.log" || failed=1
args=()
case "$mode" in quick|unit) args=(-- --group=unit);; integration|smoke) args=(-- "--group=$mode");; esac
# ${args[@]+...}: an empty array is "unbound" under set -u in the bash 3.2 that macOS ships
step tests --fixed-fps 60 res://tests/TestRunner.tscn ${args[@]+"${args[@]}"}
grep -E '^FAIL|^        - |^TESTS' "$log/tests.log" || true
# A zero exit code without the final test marker is never a passing run.
grep -qE '^TESTS: [0-9]+ passed, 0 failed' "$log/tests.log" || failed=1
if [ "$failed" -eq 0 ]; then echo 'RESULT: all checks passed';
else echo 'RESULT: checks failed'; tail -n 35 "$log/import.log" "$log/resources.log" "$log/tests.log"; fi
echo "Full logs retained: $log"
exit "$failed"
