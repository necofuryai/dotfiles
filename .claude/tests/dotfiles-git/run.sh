#!/bin/sh
# Regression suite for dot_local/bin/executable_dotfiles-git.
#
#   sh .claude/tests/dotfiles-git/run.sh [wrapper-script]
#
# Tests the source copy in this repository by default; pass a path to test
# another copy (for example the deployed ~/.local/bin/dotfiles-git). Every
# case runs with DOTFILES_GIT_DRY_RUN=1, so an accepted command prints the git
# command instead of running it and nothing in the repository changes.
#
# Each line of cases.txt is "<expected exit>::<arguments>" (0 = accepted,
# 2 = rejected); blank lines and # comments are skipped. Arguments are split
# on spaces with globbing off, so a case cannot contain a space. @MSG@ becomes
# the absolute path of a readable temporary file.

here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../.." && pwd)
wrapper=${1:-$root/dot_local/bin/executable_dotfiles-git}
cases=$here/cases.txt

[ -f "$wrapper" ] || { echo "run.sh: wrapper not found: $wrapper" >&2; exit 1; }

# macOS mktemp ignores $TMPDIR without a template, and the Bash sandbox of
# Claude Code only allows writes under its own $TMPDIR.
msg=$(mktemp "${TMPDIR:-/tmp}/dotfiles-git-test.XXXXXX") || exit 1
trap 'rm -f "$msg"' EXIT
printf 'test\n' > "$msg"

set -f
pass=0
fail=0
while IFS= read -r line; do
  case "$line" in ''|\#*) continue ;; esac
  exp=${line%%::*}
  args=$(printf '%s' "${line#*::}" | sed "s|@MSG@|$msg|g")
  # shellcheck disable=SC2086 # word splitting is the point
  DOTFILES_GIT_DRY_RUN=1 sh "$wrapper" $args >/dev/null 2>&1
  got=$?
  if [ "$got" = "$exp" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL expect=%s got=%s  dotfiles-git %s\n' "$exp" "$got" "$args"
  fi
done < "$cases"
printf 'pass=%d fail=%d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
