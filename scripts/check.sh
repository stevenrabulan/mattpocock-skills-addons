#!/usr/bin/env bash
# Check every skill before publishing.
#
# Usage:
#   bash scripts/check.sh "Jane Doe" Acme     # structure checks + your personal terms
#   bash scripts/check.sh --allow-no-terms    # structure checks only (CI)
#
# Personal terms can also live one per line in .check-terms (gitignored), so
# the terms themselves are never published. Good terms: your name, employers,
# hostnames, home paths. A line starting with ! is an allowed string instead:
# it is ignored wherever it appears (e.g. !yourname/this-repo, so the install
# command may name the repo's owner). Matching ignores case.
#
# Fails when:
#   - a folder under skills/ has no SKILL.md
#   - a SKILL.md lacks `name` or `description` frontmatter
#   - a skill's `name` differs from its folder name
#   - a skill has no row in the README table (a row starting `| \`<name>\` |`)
#   - a personal term appears in any tracked or untracked, non-ignored file
#     (LICENSE is skipped: it names the copyright holder on purpose)
#   - no terms are configured, unless --allow-no-terms is passed
#
# Exits 0 when everything passes, 1 otherwise.

set -uo pipefail
cd "$(dirname "$0")/.."

ALLOW_NO_TERMS=0
TERMS=()
ALLOWED=()
for arg in "$@"; do
  case "$arg" in
    --allow-no-terms) ALLOW_NO_TERMS=1 ;;
    *) TERMS+=("$arg") ;;
  esac
done
if [ -f .check-terms ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|\#*) continue ;;
      !*) ALLOWED+=("${line#!}") ;;
      *) TERMS+=("$line") ;;
    esac
  done < .check-terms
fi

FAILED=0
fail() { FAILED=1; printf 'FAIL %s\n' "$1"; }

# frontmatter <file> <key>: the value of a top-level key in the leading --- block.
frontmatter() {
  awk -v key="$2" '
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    index($0, key ":") == 1 { sub("^" key ":[ \t]*", ""); print; exit }
  ' "$1"
}

# --- structure --------------------------------------------------------------
found=0
for dir in skills/*/; do
  [ -d "$dir" ] || continue
  found=1
  folder="$(basename "$dir")"
  file="$dir/SKILL.md"
  if [ ! -f "$file" ]; then
    fail "skills/$folder: no SKILL.md"
    continue
  fi
  name="$(frontmatter "$file" name)"
  desc="$(frontmatter "$file" description)"
  [ -n "$name" ] || fail "skills/$folder/SKILL.md: missing name"
  [ -n "$desc" ] || fail "skills/$folder/SKILL.md: missing description"
  if [ -n "$name" ] && [ "$name" != "$folder" ]; then
    fail "skills/$folder/SKILL.md: name \"$name\" does not match folder \"$folder\""
  fi
  if ! grep -Eq "^\|[[:space:]]*\`$folder\`[[:space:]]*\|" README.md 2>/dev/null; then
    fail "skills/$folder: no row in the README table"
  fi
done
[ "$found" -eq 1 ] || fail "skills/: no skills found"

# --- personal data ----------------------------------------------------------
list_files() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    { git ls-files; git ls-files --others --exclude-standard; } | sort -u
  else
    find . -type f -not -path './.git/*' | sed 's|^\./||'
  fi | grep -vx -e 'LICENSE' -e '\.check-terms' || true
}

# drop_allowed <term>: keep grep hits (file:line:text) whose text still holds
# the term once every allowed string is removed.
drop_allowed() {
  awk -v term="$1" -v allowed="$(printf '%s\n' "${ALLOWED[@]+"${ALLOWED[@]}"}")" '
    BEGIN { n = split(tolower(allowed), allow, "\n"); term = tolower(term) }
    {
      text = $0
      sub(/^[^:]*:[0-9]+:/, "", text)
      text = tolower(text)
      for (i = 1; i <= n; i++) {
        if (allow[i] == "") continue
        while ((p = index(text, allow[i])) > 0)
          text = substr(text, 1, p - 1) substr(text, p + length(allow[i]))
      }
      if (index(text, term) > 0) print
    }'
}

if [ "${#TERMS[@]}" -gt 0 ]; then
  for term in "${TERMS[@]}"; do
    hits="$(list_files | tr '\n' '\0' | xargs -0 grep -InFH -i -- "$term" 2>/dev/null | drop_allowed "$term" || true)"
    if [ -n "$hits" ]; then
      fail "personal term found:"
      printf '%s\n' "$hits" | cut -d: -f1,2 | sed 's/^/     /'
    fi
  done
elif [ "$ALLOW_NO_TERMS" -eq 0 ]; then
  fail "no personal terms configured: pass them as arguments or list them in .check-terms (or pass --allow-no-terms)"
fi

if [ "$FAILED" -eq 1 ]; then
  printf '\nCheck failed.\n'
  exit 1
fi
printf 'ok   all skills pass\n'
