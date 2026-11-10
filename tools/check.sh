#!/usr/bin/env bash
# One command that says whether the project is healthy.
#   tools/check.sh            import, load every file, run all tests
#   tools/check.sh quick      import, load every file, unit tests only
# Needs Godot 4.7.2. Uses `godot` on the PATH, or set GODOT=/path/to/the/godot/binary.
# Exit code 0 means everything passed.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
mode="${1:-all}"
log="$(mktemp -d)"
fail=0

echo "Godot: $("$GODOT" --version 2>/dev/null || echo 'NOT FOUND (set GODOT=/path/to/godot)')"

echo "1/3 import (builds game/.godot from nothing if it is missing)"
"$GODOT" --headless --path game --import > "$log/import.log" 2>&1
code=$?
problems=$(grep -c -E "^(ERROR|SCRIPT ERROR|WARNING)" "$log/import.log" || true)
echo "    exit $code, $problems error/warning lines"
[ "$code" -ne 0 ] && fail=1
[ "$problems" -ne 0 ] && { grep -E -A3 "^(ERROR|SCRIPT ERROR|WARNING)" "$log/import.log" | head -40; }

echo "2/3 every script, scene and resource loads"
"$GODOT" --headless --path game res://tools/CheckScripts.tscn > "$log/check.log" 2>&1
code=$?
grep -E "checked [0-9]+ files" "$log/check.log" | sed 's/^/    /'
if [ "$code" -ne 0 ] || ! grep -q "0 problem(s)" "$log/check.log"; then
  fail=1
  grep -v "^$" "$log/check.log" | tail -40
fi

echo "3/3 tests"
if [ "$mode" = "quick" ]; then
  "$GODOT" --headless --fixed-fps 60 --path game res://tests/TestRunner.tscn -- --group=unit > "$log/tests.log" 2>&1
else
  "$GODOT" --headless --fixed-fps 60 --path game res://tests/TestRunner.tscn > "$log/tests.log" 2>&1
fi
code=$?
grep -E "^FAIL|^        - |^TESTS" "$log/tests.log" | sed 's/^/    /'
[ "$code" -ne 0 ] && fail=1

echo
if [ "$fail" -eq 0 ]; then echo "RESULT: all checks passed"; else echo "RESULT: something failed (full logs in $log)"; fi
exit "$fail"
