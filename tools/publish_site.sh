#!/usr/bin/env bash
# Records build/web as a new commit on the local `gh-pages` branch (the branch GitHub
# Pages serves). Does not switch branches, does not change project files, does not push.
set -euo pipefail
cd "$(dirname "$0")/.."
test -s build/web/index.html || { echo "build/web is missing: run tools/build.sh web first"; exit 1; }
touch build/web/.nojekyll
version="$(grep -m1 '^config/version=' game/project.godot | cut -d'"' -f2)"
source_commit="$(git rev-parse --short HEAD)"
export GIT_INDEX_FILE="$(mktemp -u)"
git --work-tree="$PWD/build/web" add -A -f . >/dev/null
tree="$(git write-tree)"
rm -f "$GIT_INDEX_FILE"; unset GIT_INDEX_FILE
parent=()
if git rev-parse -q --verify refs/heads/gh-pages >/dev/null; then parent=(-p "$(git rev-parse refs/heads/gh-pages)"); fi
commit="$(git commit-tree "$tree" ${parent[@]+"${parent[@]}"} -m "Web build $version (from $source_commit)")"
git update-ref refs/heads/gh-pages "$commit"
echo "gh-pages now at $(git rev-parse --short gh-pages): web build $version from $source_commit"
git ls-tree -r --name-only gh-pages | wc -l | sed 's/^ */files: /'
