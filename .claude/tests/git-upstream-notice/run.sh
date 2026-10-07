#!/bin/sh
# Regression suite for dot_claude/hooks/executable_git-upstream-notice.sh.
#
#   sh .claude/tests/git-upstream-notice/run.sh [hook-script]
#
# Tests the source copy in this repository by default; pass a path to test
# another copy (for example the deployed ~/.claude/hooks/git-upstream-notice.sh).
# Each line of cases.txt is
#   <expect>::<must contain>::<must not contain>::<hook input JSON>
# where <expect> is notice (prints additionalContext for the input's event)
# or silent (prints nothing), and either substring may be - for no check.
# <HERE> in the JSON is replaced with this directory, so a case can point
# tool_response.persistedOutputPath at persisted-output.txt. Every case must
# exit 0. Blank lines and # comments are skipped. Needs jq, which the hook
# itself also uses.

here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../.." && pwd)
hook=${1:-$root/dot_claude/hooks/executable_git-upstream-notice.sh}
cases=$here/cases.txt

command -v jq >/dev/null || { echo 'run.sh: jq is required' >&2; exit 1; }
[ -f "$hook" ] || { echo "run.sh: hook not found: $hook" >&2; exit 1; }

pass=0
fail=0
while IFS= read -r line; do
  case "$line" in ''|\#*) continue ;; esac
  exp=${line%%::*}; rest=${line#*::}
  must=${rest%%::*}; rest=${rest#*::}
  mustnot=${rest%%::*}; input=${rest#*::}
  input=$(printf '%s' "$input" | sed "s#<HERE>#$here#g")

  out=$(printf '%s' "$input" | sh "$hook" 2>/dev/null)
  rc=$?
  why=
  if [ "$rc" -ne 0 ]; then
    why="exit=$rc"
  elif [ "$exp" = silent ]; then
    [ -z "$out" ] || why='printed output'
  else
    want=$(printf '%s' "$input" | jq -r '.hook_event_name // "PostToolUse"')
    case "$want" in PostToolUse|PostToolUseFailure) ;; *) want=PostToolUse ;; esac
    ctx=$(printf '%s' "$out" | jq -r --arg e "$want" \
      'select(.hookSpecificOutput.hookEventName == $e) | .hookSpecificOutput.additionalContext // empty' 2>/dev/null)
    if [ -z "$ctx" ]; then
      why="no additionalContext for $want"
    elif [ "$must" != - ] && ! printf '%s' "$ctx" | grep -qF -- "$must"; then
      why="missing: $must"
    elif [ "$mustnot" != - ] && printf '%s' "$ctx" | grep -qF -- "$mustnot"; then
      why="unexpected: $mustnot"
    fi
  fi

  if [ -z "$why" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL [%s] %s  %.100s\n' "$exp" "$why" "$input"
  fi
done < "$cases"
printf 'pass=%d fail=%d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
