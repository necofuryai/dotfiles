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
#   chezmoi add (alias manage)  -T/--template, -a/--autotemplate, --force
#       rewrites an existing .tmpl with rendered literals, baking an absolute
#       home path into a public repository. Plain `chezmoi add` on a template
#       prompts first and fails safely in a non-TTY, so it stays allowed.
#   chezmoi apply / update / init -a/--apply  --force
#       overwrites a drifted target silently, discarding permission approvals
#       that Claude Code wrote into ~/.claude/settings.json.
#   -c/--config, -S/--source, -D/--destination, -W/--working-tree,
#   -o/--output, --persistent-state, --cache, --override-data(-file)
#       point chezmoi at a config, source, target, git working tree, output,
#       state, cache or template data of the caller's choosing. A config can
#       declare hooks and a source can hold templates that call `output`, so a
#       file written from inside the sandbox would execute outside it.
#   chezmoi execute-template / cd / edit
#       run a template, a shell or an editor outside the sandbox. Asking for
#       their help (`chezmoi help edit`, `chezmoi edit --help`) passes.
#
# shfmt parses the command as zsh, the shell Claude Code runs it in, and the
# rules are checked against the words of every simple command whose name is
# chezmoi: after ; && || | or a newline, and inside $( ), backquotes, ( ),
# { }, if/for/while bodies and <( ). A word is its text with quotes and
# backslashes removed, so "--config", ch""ezmoi and \chezmoi are seen; an
# expansion such as $f adds nothing to it, and an unquoted {a,b} becomes two
# words. The name may be a path (/opt/homebrew/bin/chezmoi) or follow a
# wrapper such as env, timeout, nice, nohup or noglob and its options. The
# script that sh/bash/zsh -c runs (the operand after -c, not $0, $1, ...) and
# the words eval joins are parsed in turn. The rules match whole words, so
# chezmoi in a grep pattern, a -m message, a comment or a heredoc body is not
# an invocation, and `chezmoi git commit -m "x --config"` passes.
#
# A command that mentions chezmoi is blocked when shfmt cannot parse it, when
# jq cannot read the syntax tree, or when shfmt is missing or not at major
# version 3, whose JSON layout this script reads: the guard cannot tell then
# whether chezmoi runs in it. shfmt 3.14 rejects some valid zsh: the short
# loop and brace forms (`for f (a b) cmd`, `if [[ x ]] { }`, `repeat 2 { }`),
# `{ } always { }`, `for k v in ...` and anonymous functions with arguments.
#
# This is friction against a confused model, not a boundary against a
# deliberate one: `f=--config; chezmoi status $f x` passes, and so does
# chezmoi run by xargs, find -exec or a script fed to sh on stdin
# (`echo ... | sh`, `sh <<EOF`), which run inside the sandbox. The boundary
# is the sandbox denyWrite on ~/.config/chezmoi/chezmoi.* plus the permission
# rules. Exit 2 blocks the call; stderr reaches Claude.

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
# Quotes, backslashes and newlines are dropped for this cheap test only, so
# that ch""ezmoi, \chezmoi and a continued ch\<newline>ezmoi reach the parser.
case $(printf '%s' "$cmd" | tr -d "\"'\\\\\n") in *chezmoi*) ;; *) exit 0 ;; esac

block() {
  printf '%s\n' "BLOCKED: $1" >&2
  exit 2
}

shfmt=/opt/homebrew/bin/shfmt
case $("$shfmt" --version 2>/dev/null) in
  3.* | v3.*) ;;
  *) block "chezmoi-guard needs shfmt 3.x at $shfmt to read a command that mentions chezmoi. Install it with brew install shfmt (~/.Brewfile lists it); after a major upgrade, update the guard and run .claude/tests/chezmoi-guard/run.sh in the chezmoi source repository." ;;
esac

# Reads shfmt's syntax tree and prints one line per finding: the name of a
# rule that a chezmoi invocation breaks, or `<dialect> <JSON string>` for a
# script that sh -c or eval would run, which check parses in turn. $lang is
# the dialect of the tree being read, which eval inherits.
program='
# The text of a word: quotes and backslashes removed, expansions dropped.
def text:
  [.Parts[]? |
    if .Type == "Lit" then .Value | gsub("\\\\(?<c>.)"; "\(.c)")
    elif .Type == "SglQuoted" then .Value
    elif .Type == "DblQuoted" then text
    else "" end] | join("");

# Brace expansion: {edit,x} becomes the two words edit and x.
def braces:
  (capture("^(?<pre>[^{]*)[{](?<alts>[^{}]*,[^{}]*)[}](?<post>.*)$") // null) as $m
  | if $m == null then . else $m.alts | split(",")[] | $m.pre + . + $m.post | braces end;

# Drops leading wrappers with their options and values, so that
# `timeout -s KILL 5 chezmoi edit` starts at chezmoi. env -S splits its
# string into words.
def unwrap:
  if length > 0 and (.[0] | test("^(.*/)?(env|command|builtin|exec|nice|nohup|timeout|noglob|nocorrect|repeat|coproc|-)$")) then
    .[1:]
    | until(length == 0 or (.[0] | test("^-|=|^[0-9.]+[smhd]?$") | not);
        if .[0] == "-S" then (.[1] // "" | [splits(" +")] | map(select(. != ""))) + .[2:]
        elif .[0] | test("^-[aCknPsu]$|^--(signal|kill-after)$") then .[2:]
        else .[1:] end)
    | unwrap
  else . end;

# The script that sh/bash/zsh -c runs: the first operand once a flag cluster
# with c (-c, -lc, -ec) has been seen. -o/-O (also at the end of -euo) and
# --rcfile/--init-file take a value; the operands after the script are $0,
# $1, ... Without -c the first operand is a script file, which is not read.
def script($c):
  if length == 0 then empty
  elif .[0] | test("^[-+].") then
    (.[0] | test("^-[A-Za-z]*c")) as $new
    | if .[0] | test("^[-+][A-Za-z]*[oO]$|^--(rcfile|init-file)$") then .[2:] else .[1:] end
    | script($c or $new)
  elif $c then .[0]
  else empty end;

# The letters a short-flag cluster sets. A flag that takes a value ends it,
# so -nc/tmp/x sets n and c while -pabsolute sets only p. chezmoi flags that
# take a value: c, S, D, W, o, -x/-i types, -f format, -p path style,
# -d depth and -C config path.
def shorts: (capture("^-(?<s>[A-Za-z]*?[cSDWoxifpdC]|[A-Za-z]+)") // {s: ""}).s;

def has(re): any(.[]; test(re));
def sets(letters): any(.[]; shorts | test("[" + letters + "]"));

# `chezmoi help edit` and `chezmoi edit --help` print help and run nothing.
# After -- a --help is an argument, and `chezmoi edit help` edits a file.
def help: .[0] == "help" or (.[:(index("--") // length)] | any(.[]; . == "--help" or . == "-h"));

.. | objects | select(.Type == "CallExpr") | [.Args[]? | text | braces] | unwrap
| if length == 0 then empty
  elif .[0] | test("^(=|.*/)?chezmoi$") then
    .[1:]
    | if has("^(add|manage)$") and (has("^--(template|autotemplate|force)(=|$)") or sets("Ta")) then "add"
      elif has("^--force(=|$)") and (has("^(apply|update)$|^--apply(=|$)") or (has("^init$") and sets("a"))) then "force"
      elif has("^--(config|source|destination|working-tree|output|persistent-state|cache|override-data|override-data-file)(=|$)") or sets("cSDWo") then "redirect"
      elif has("^(execute-template|cd|edit)$") and (help | not) then "run"
      else empty end
  elif .[0] | test("^(.*/)?(sh|bash|dash|ksh)$") then .[1:] | script(false) | "bash " + tojson
  elif .[0] | test("^(.*/)?zsh$") then .[1:] | script(false) | "zsh " + tojson
  elif .[0] == "eval" then $lang + " " + (.[1:] | if .[0] == "--" then .[1:] else . end | join(" ") | tojson)
  else empty end
'

# $1 is the shfmt dialect (zsh, or bash for a script that sh or bash runs)
# and $2 the command.
check() {
  tree=$(printf '%s\n' "$2" | "$shfmt" -ln "$1" --to-json 2>/dev/null) ||
    block "chezmoi-guard could not parse this command as $1 ($(printf '%s\n' "$2" | "$shfmt" -ln "$1" --to-json 2>&1 >/dev/null)), so it cannot tell whether chezmoi runs in it. Write zsh short forms such as for f (a b) cmd in the long form, split it into simpler commands, or read files with the Read and Grep tools."
  found=$(printf '%s' "$tree" | jq -r --arg lang "$1" "$program") ||
    block "chezmoi-guard could not read the syntax tree from shfmt $("$shfmt" --version). Update the guard and run .claude/tests/chezmoi-guard/run.sh in the chezmoi source repository."
  for finding in $found; do
    case $finding in
      add) block 'chezmoi add with -T/--template, -a/--autotemplate or --force rewrites a .tmpl with rendered literals (exit 0, no prompt, no warning) and bakes an absolute home path into this public repository. Edit the .tmpl by hand instead. See the hard rules in CLAUDE.md of the chezmoi source repository.' ;;
      force) block 'chezmoi apply --force (also update / init --apply) overwrites a drifted target with no prompt and no output, discarding Claude Code permission approvals in ~/.claude/settings.json. Run plain apply and answer skip at the drift prompt. See the hard rules in CLAUDE.md of the chezmoi source repository.' ;;
      redirect) block 'chezmoi with -c/--config, -S/--source, -D/--destination, -W/--working-tree, -o/--output, --persistent-state, --cache or --override-data(-file). chezmoi runs outside the sandbox, so a config, source or template data written from inside it would execute outside it. Use the default config, source and destination.' ;;
      run) block 'chezmoi execute-template / cd / edit runs a template, a shell or an editor outside the sandbox. Edit the target with the Edit tool and run chezmoi re-add instead.' ;;
      bash\ * | zsh\ *) check "${finding%% *}" "$(printf '%s' "${finding#* }" | jq -r .)" ;;
    esac
  done
}

set -f
IFS='
'
check zsh "$cmd"
exit 0
