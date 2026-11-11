#!/usr/bin/env bash
# Fails if a cloud-sync duplicate ("name 2.ext") is inside the project. Git ignores such
# files, but Godot loads them: a copied script declares the same class twice and a
# copied test runs twice, so checks fail and exports carry junk.
cd "$(dirname "$0")/.."
found="$(find . -path ./.git -prune -o -path ./build -prune -o -path ./game/.godot -prune -o \( -name '* 2.*' -o -name '* 3.*' -o -name '* 2' -o -name '* 3' \) -print 2>/dev/null)"
if [ -n "$found" ]; then
  echo "Cloud-sync duplicate files found; remove them before checking or building:"
  echo "$found"
  exit 1
fi
