#!/usr/bin/env bash
# Link each skill in this repo into ~/.claude/skills, so edits here are live.
# Safe to re-run. Refuses to replace anything that is not already a symlink.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -d "$REPO/skills" ] || { echo "error: $REPO/skills not found" >&2; exit 1; }

DEST="$HOME/.claude/skills"
mkdir -p "$DEST"

for dir in "$REPO"/skills/*/; do
  [ -f "$dir/SKILL.md" ] || { echo "error: $dir has no SKILL.md" >&2; exit 1; }
  path="$DEST/$(basename "$dir")"
  if [ -e "$path" ] && [ ! -L "$path" ]; then
    echo "error: $path exists and is not a symlink, move it away first" >&2
    exit 1
  fi
  ln -sfn "${dir%/}" "$path"
  echo "linked $path -> ${dir%/}"
done
