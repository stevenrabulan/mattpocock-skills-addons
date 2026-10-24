#!/usr/bin/env bash
# Black-box tests for scripts/check.sh and link.sh.
#
# Each test builds a throwaway repo with a fixture skills tree, copies the
# scripts in, and asserts only exit codes, output, and the links created
# under a throwaway HOME.
#
# Usage: bash scripts/check.test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TERM_="ZebraCorp"

PASS=0
FAIL=0
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# make_repo <name>: a git repo with two valid skills, a README table, the scripts.
make_repo() {
  local dir="$WORK/$1"
  mkdir -p "$dir/scripts" "$dir/skills/alpha" "$dir/skills/beta"
  cp "$ROOT/scripts/check.sh" "$dir/scripts/check.sh"
  cp "$ROOT/link.sh" "$dir/link.sh"
  for s in alpha beta; do
    printf -- '---\nname: %s\ndescription: Does %s things.\n---\n\nBody.\n' "$s" "$s" > "$dir/skills/$s/SKILL.md"
  done
  printf '# Fixture\n\n| Skill | What |\n| --- | --- |\n| `alpha` | a |\n| `beta` | b |\n' > "$dir/README.md"
  printf '.check-terms\nignored/\n' > "$dir/.gitignore"
  printf 'Copyright %s\n' "$TERM_" > "$dir/LICENSE"
  (
    cd "$dir"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test"
    git add -A
    git commit -q -m init
  )
  echo "$dir"
}

# check <dir> [args...]: sets OUT and CODE.
check() {
  local dir="$1"; shift
  OUT="$(cd "$dir" && bash scripts/check.sh "$@" 2>&1)"
  CODE=$?
}

# link <dir> <home>: sets OUT and CODE.
link() {
  OUT="$(HOME="$2" bash "$1/link.sh" 2>&1)"
  CODE=$?
}

ok() { PASS=$((PASS + 1)); printf 'ok   %s\n' "$1"; }
bad() {
  FAIL=$((FAIL + 1))
  printf 'FAIL %s\n' "$1"
  printf '%s\n' "$OUT" | sed 's/^/     | /'
}
expect_code() { if [ "$CODE" -eq "$2" ]; then ok "$1"; else bad "$1 (exit $CODE, want $2)"; fi; }
expect_out() { if printf '%s' "$OUT" | grep -qF -- "$2"; then ok "$1"; else bad "$1 (missing: $2)"; fi; }
expect_no_out() { if printf '%s' "$OUT" | grep -qF -- "$2"; then bad "$1 (unexpected: $2)"; else ok "$1"; fi; }

# --- checker ----------------------------------------------------------------
d=$(make_repo valid)
check "$d" "$TERM_"
expect_code "valid tree passes (LICENSE is skipped)" 0

d=$(make_repo no-skill-md)
rm "$d/skills/beta/SKILL.md"
check "$d" "$TERM_"
expect_code "missing SKILL.md fails" 1
expect_out "missing SKILL.md names the folder" "skills/beta: no SKILL.md"

d=$(make_repo no-description)
printf -- '---\nname: beta\n---\n' > "$d/skills/beta/SKILL.md"
check "$d" "$TERM_"
expect_code "missing description fails" 1
expect_out "missing description names the file" "skills/beta/SKILL.md: missing description"

d=$(make_repo mismatch)
printf -- '---\nname: gamma\ndescription: x\n---\n' > "$d/skills/beta/SKILL.md"
check "$d" "$TERM_"
expect_code "name/folder mismatch fails" 1
expect_out "mismatch names both" 'name "gamma" does not match folder "beta"'

d=$(make_repo no-readme-row)
printf '# Fixture\n\n| Skill | What |\n| --- | --- |\n| `alpha` | a |\n' > "$d/README.md"
check "$d" "$TERM_"
expect_code "skill missing from README table fails" 1
expect_out "missing row names the skill" "skills/beta: no row in the README table"

d=$(make_repo term-tracked)
printf 'Built at %s.\n' "$TERM_" >> "$d/skills/alpha/SKILL.md"
check "$d" "$TERM_"
expect_code "personal term in a skill fails" 1
expect_out "term hit names the file" "skills/alpha/SKILL.md"
expect_no_out "term hit does not echo the term" "Built at"

d=$(make_repo term-untracked)
printf 'zebracorp notes\n' > "$d/notes.txt"
check "$d" "$TERM_"
expect_code "term in an untracked file fails, any case" 1
expect_out "untracked hit names the file" "notes.txt"

d=$(make_repo term-ignored)
mkdir -p "$d/ignored"
printf '%s\n' "$TERM_" > "$d/ignored/private.txt"
check "$d" "$TERM_"
expect_code "term in an ignored file passes" 0

d=$(make_repo terms-file)
printf '# my terms\n%s\n' "$TERM_" > "$d/.check-terms"
check "$d"
expect_code "terms from .check-terms; the file never matches itself" 0
printf 'by %s\n' "$TERM_" > "$d/x.txt"
check "$d"
expect_code "terms from .check-terms are searched" 1

d=$(make_repo allowed)
printf 'npx skills add zebracorp-user/addons\n' >> "$d/README.md"
printf '%s\n!zebracorp-user/addons\n' "$TERM_" > "$d/.check-terms"
check "$d"
expect_code "an allowed string (!line in .check-terms) is not a hit" 0
printf 'Made by ZebraCorp, see zebracorp-user/addons\n' > "$d/y.txt"
check "$d"
expect_code "the term elsewhere on the same line still fails" 1
expect_out "that hit names the file" "y.txt"

d=$(make_repo no-terms)
check "$d"
expect_code "no terms fails" 1
expect_out "no terms says why" "no personal terms configured"
check "$d" --allow-no-terms
expect_code "--allow-no-terms passes" 0

# --- link.sh ----------------------------------------------------------------
d=$(make_repo linking)
h="$WORK/home-linking"
link "$d" "$h"
expect_code "link.sh succeeds" 0
for s in alpha beta; do
  if [ -L "$h/.claude/skills/$s" ] && [ "$(readlink "$h/.claude/skills/$s")" = "$d/skills/$s" ]; then
    ok "link for $s points at the repo folder"
  else
    bad "link for $s points at the repo folder"
  fi
done
before="$(ls -l "$h/.claude/skills")"
link "$d" "$h"
expect_code "second run succeeds" 0
if [ "$(ls -l "$h/.claude/skills")" = "$before" ]; then ok "second run changes nothing"; else bad "second run changes nothing"; fi

d=$(make_repo real-folder)
h="$WORK/home-real"
mkdir -p "$h/.claude/skills/beta"
printf 'mine\n' > "$h/.claude/skills/beta/SKILL.md"
link "$d" "$h"
expect_code "real folder in the way fails" 1
expect_out "real folder error names the path" "$h/.claude/skills/beta exists and is not a symlink"
if [ ! -L "$h/.claude/skills/beta" ] && [ "$(cat "$h/.claude/skills/beta/SKILL.md")" = "mine" ]; then
  ok "real folder left untouched"
else
  bad "real folder left untouched"
fi

d=$(make_repo link-no-skill-md)
rm "$d/skills/alpha/SKILL.md"
link "$d" "$WORK/home-nomd"
expect_code "link.sh fails on a folder without SKILL.md" 1

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
