#!/bin/sh
# Claude Code PreToolUse hook (matcher: Bash).
#
# Blocks the two chezmoi invocations that lose data with no prompt and no
# output. Both are documented as hard rules in the chezmoi source repository's
# CLAUDE.md; this hook is the mechanical guard, the permission list is not
# (Bash(...) permission patterns are prefix matches and cannot see a flag).
#
#   chezmoi add  -T/--template, -a/--autotemplate, --force
#       rewrites an existing .tmpl with rendered literals, baking an absolute
#       home path into a public repository. Plain `chezmoi add` on a template
#       prompts first and fails safely in a non-TTY, so it stays allowed.
#   chezmoi apply / update / --apply  --force
#       overwrites a drifted target silently, discarding permission approvals
#       that Claude Code wrote into ~/.claude/settings.json.
#
# Matching is per chezmoi segment (from `chezmoi` up to ; & |), so flags of
# unrelated commands on the same line are ignored, global flags before the
# subcommand (`chezmoi --force apply`) are still seen, and short flags inside
# a cluster (-rT) are caught. Exit 2 blocks the call; stderr reaches Claude.

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -n "$cmd" ] || exit 0
case "$cmd" in *chezmoi*) ;; *) exit 0 ;; esac

set -f
oldifs=$IFS
IFS='
'
for seg in $(printf '%s\n' "$cmd" | grep -oE 'chezmoi[^;&|]*'); do
  if printf '%s' "$seg" | grep -qE '(^|[[:space:]])add([[:space:]]|$)' &&
     printf '%s' "$seg" | grep -qE '(^|[[:space:]])(--template|--autotemplate|--force|-[A-Za-z]*[Ta][A-Za-z]*)([[:space:]]|=|$)'; then
    printf '%s\n' 'BLOCKED: chezmoi add with -T/--template, -a/--autotemplate or --force rewrites a .tmpl with rendered literals (exit 0, no prompt, no warning) and bakes an absolute home path into this public repository. Edit the .tmpl by hand instead. See the hard rules in CLAUDE.md of the chezmoi source repository.' >&2
    exit 2
  fi
  if printf '%s' "$seg" | grep -qE '(^|[[:space:]])(apply|update|--apply)([[:space:]]|$)' &&
     printf '%s' "$seg" | grep -qE '(^|[[:space:]])--force([[:space:]]|=|$)'; then
    printf '%s\n' 'BLOCKED: chezmoi apply --force (also update / --apply) overwrites a drifted target with no prompt and no output, discarding Claude Code permission approvals in ~/.claude/settings.json. Run plain apply and answer skip at the drift prompt. See the hard rules in CLAUDE.md of the chezmoi source repository.' >&2
    exit 2
  fi
done
IFS=$oldifs
exit 0
