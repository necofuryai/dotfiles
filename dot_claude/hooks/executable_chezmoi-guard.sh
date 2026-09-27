#!/bin/sh
# Claude Code PreToolUse hook (matcher: Bash).
#
# chezmoi runs outside the Bash sandbox (sandbox.excludedCommands), and
# Bash(...) permission patterns are prefix matches that cannot see a flag, so
# `Bash(chezmoi status:*)` also approves `chezmoi status --config x`. This hook
# is the mechanical guard for the chezmoi invocations that must not run from
# Claude. The data-loss rules are documented as hard rules in the chezmoi
# source repository's CLAUDE.md.
#
#   chezmoi add  -T/--template, -a/--autotemplate, --force
#       rewrites an existing .tmpl with rendered literals, baking an absolute
#       home path into a public repository. Plain `chezmoi add` on a template
#       prompts first and fails safely in a non-TTY, so it stays allowed.
#   chezmoi apply / update / --apply  --force
#       overwrites a drifted target silently, discarding permission approvals
#       that Claude Code wrote into ~/.claude/settings.json.
#   -c/--config, -S/--source, -D/--destination, -W/--working-tree,
#   -o/--output, --persistent-state, --cache, --override-data(-file)
#       point chezmoi at a config, source, target, git working tree, output,
#       state, cache or template data of the caller's choosing. A config can
#       declare hooks and a source can hold templates that call `output`, so a
#       file written from inside the sandbox would execute outside it.
#   chezmoi execute-template / cd / edit
#       run a template, a shell or an editor outside the sandbox.
#   chezmoi git
#       runs any git command outside the sandbox. The git ask and deny rules
#       match `git push` or `git reset`, not `chezmoi git -- push`, and Claude
#       Code's refusal to exempt `git -c` / `git -C` covers a bare git only,
#       so `chezmoi git -- -c alias.x=!cmd x` would run a shell command of
#       the caller's choosing. dotfiles-git covers the reads and the commit
#       path.
#
# A backslash-newline continuation is joined into a space first and any other
# newline becomes `;`: Claude Code still runs `chezmoi \<newline>--config x`
# outside the sandbox, while grep reads one line at a time. Quotes and
# backslashes are stripped next, so "--config" and ch""ezmoi are seen. A
# segment starts where `chezmoi` stands in command position (the
# start, whitespace, ; & | ( ` =, or a .../bin/ path) and runs up to the next
# ; & |. A path that only contains the word, such as the -C argument of
# `git -C ~/.local/share/chezmoi log -S foo`, is not a segment. Global flags
# before the subcommand are seen, and short flags are caught inside a cluster
# (-rT) and with an attached value (-c/tmp/x).
#
# This is friction against a confused model, not a boundary against a
# deliberate one: `f=--config; chezmoi status $f x` passes. The boundary is
# the sandbox denyWrite on ~/.config/chezmoi/chezmoi.* plus the permission
# rules. Exit 2 blocks the call; stderr reaches Claude.

input=$(cat)
cmd=$(printf '%s' "$input" |
      jq -r '.tool_input.command // empty | gsub("\\\\\n"; " ") | gsub("\n"; ";")' |
      tr -d "\"'\\\\")
[ -n "$cmd" ] || exit 0
case "$cmd" in *chezmoi*) ;; *) exit 0 ;; esac

block() {
  printf '%s\n' "BLOCKED: $1" >&2
  exit 2
}

set -f
oldifs=$IFS
IFS='
'
for seg in $(printf '%s\n' "$cmd" |
             grep -oE '(^|[[:space:];&|(`=]|/bin/)chezmoi([[:space:]][^;&|]*)?'); do
  if printf '%s' "$seg" | grep -qE '(^|[[:space:]])add([[:space:]]|$)' &&
     printf '%s' "$seg" | grep -qE '(^|[[:space:]])(--template|--autotemplate|--force|-[A-Za-z]*[Ta][A-Za-z]*)([[:space:]]|=|$)'; then
    block 'chezmoi add with -T/--template, -a/--autotemplate or --force rewrites a .tmpl with rendered literals (exit 0, no prompt, no warning) and bakes an absolute home path into this public repository. Edit the .tmpl by hand instead. See the hard rules in CLAUDE.md of the chezmoi source repository.'
  fi
  if printf '%s' "$seg" | grep -qE '(^|[[:space:]])(apply|update|--apply)([[:space:]]|$)' &&
     printf '%s' "$seg" | grep -qE '(^|[[:space:]])--force([[:space:]]|=|$)'; then
    block 'chezmoi apply --force (also update / --apply) overwrites a drifted target with no prompt and no output, discarding Claude Code permission approvals in ~/.claude/settings.json. Run plain apply and answer skip at the drift prompt. See the hard rules in CLAUDE.md of the chezmoi source repository.'
  fi
  if printf '%s' "$seg" | grep -qE '(^|[[:space:]])--(config|source|destination|working-tree|output|persistent-state|cache|override-data|override-data-file)([[:space:]]|=|$)' ||
     printf '%s' "$seg" | grep -qE '(^|[[:space:]])-[A-Za-z]*[cSDWo]'; then
    block 'chezmoi with -c/--config, -S/--source, -D/--destination, -W/--working-tree, -o/--output, --persistent-state, --cache or --override-data(-file). chezmoi runs outside the sandbox, so a config, source or template data written from inside it would execute outside it. Use the default config, source and destination.'
  fi
  if printf '%s' "$seg" | grep -qE '(^|[[:space:]])(execute-template|cd|edit)([[:space:]]|$)'; then
    block 'chezmoi execute-template / cd / edit runs a template, a shell or an editor outside the sandbox. Edit the target with the Edit tool and run chezmoi re-add instead.'
  fi
  if printf '%s' "$seg" | grep -qE '(^|[[:space:]])git([[:space:]]|$)'; then
    block 'chezmoi git runs any git command outside the sandbox, past the git ask and deny rules (they match "git push", not "chezmoi git -- push"). Use dotfiles-git status/diff/log/add/commit/push, or plain git from a session opened in the chezmoi source repository.'
  fi
done
IFS=$oldifs
exit 0
