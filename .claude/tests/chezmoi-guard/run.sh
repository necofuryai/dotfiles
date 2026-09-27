#!/bin/sh
# Regression suite for dot_claude/hooks/executable_chezmoi-guard.sh.
#
#   sh .claude/tests/chezmoi-guard/run.sh [guard-script]
#
# Tests the source copy in this repository by default; pass a path to test
# another copy (for example the deployed ~/.claude/hooks/chezmoi-guard.sh).
# Each line of cases.txt is "<expected exit>::<command>" (2 = blocked,
# 0 = allowed); blank lines and # comments are skipped. Needs jq, which the
# guard itself also uses.
#
# Run it by path, as above. The guard reads the whole Bash command line, so a
# test command that spells out the cases inline would be blocked by the
# deployed guard before it ran.

here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../.." && pwd)
guard=${1:-$root/dot_claude/hooks/executable_chezmoi-guard.sh}
cases=$here/cases.txt

command -v jq >/dev/null || { echo 'run.sh: jq is required' >&2; exit 1; }
[ -f "$guard" ] || { echo "run.sh: guard not found: $guard" >&2; exit 1; }

pass=0
fail=0
while IFS= read -r line; do
  case "$line" in ''|\#*) continue ;; esac
  exp=${line%%::*}
  cmd=${line#*::}
  jq -n --arg c "$cmd" '{tool_input:{command:$c}}' | sh "$guard" >/dev/null 2>&1
  got=$?
  if [ "$got" = "$exp" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL expect=%s got=%s  %s\n' "$exp" "$got" "$cmd"
  fi
done < "$cases"
printf 'pass=%d fail=%d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
