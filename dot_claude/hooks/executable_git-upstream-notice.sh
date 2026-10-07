#!/bin/sh
# Claude Code PostToolUse and PostToolUseFailure hook (matcher: Bash).
#
# Inside the Bash sandbox, Claude Code makes the session's own repositories'
# .git/config and .git/config.lock read-only (and the whole .git of any other
# repository). Anything that records an upstream then half-succeeds, and git
# prints
#
#   error: could not lock config file .git/config: Operation not permitted
#   error: unable to write upstream branch configuration
#
#   git push -u (or a bare git push under push.autoSetupRemote)
#       pushes and still exits 0; only branch.<name>.remote/merge is missing.
#   git switch -c/-C, git checkout -b/-B, git branch --track
#       create the branch, do not check it out, and exit 1; running the same
#       command again fails because the branch now exists.
#
# This hook finds the second line in the tool's result and tells Claude what
# happened and how to write only the upstream, so it neither repeats a push
# that succeeded nor assumes the upstream or the checkout exists.
#
# Where the line is: Claude Code merges the command's stderr into
# tool_response.stdout on success and into `error` (after "Exit code N") on
# failure, so every string outside tool_input is searched. Output too large to
# inline is cut to its head in stdout, and the full text is saved at
# tool_response.persistedOutputPath; the tail of that file is searched too.
#
# What it says about a push: that it succeeded only on PostToolUse, when the
# output has git's push report (a "To " line plus a ref line, human or
# --porcelain format) and no rejected ref; with a rejected ref or a failed
# call it asks Claude to read the per-ref result; "Everything up-to-date"
# means nothing was left to push; with no report at all (for example under
# -q) it asks Claude to check with git ls-remote. It blames the
# sandbox only when the lock failure says "Operation not permitted". It never
# quotes git's own fix-up hint, which git 2.56 prints as
# <remote>/refs/heads/<branch>, a name that does not resolve.
#
# Matching: only a whole line equal to git's message counts, so a command that
# merely mentions it (the command itself, `grep -n` output, `cat` of this
# file) stays silent. A whole-line copy from any source, such as `grep -o`
# output, does trigger it; the notice is harmless then. git prints the message
# in English here: Claude Code's Bash runs without LANG, and Homebrew git
# ships no Japanese catalogue. Prints nothing when the line is absent and
# always exits 0, so it can never block or fail a tool call.
#
# Tests: sh .claude/tests/git-upstream-notice/run.sh in the chezmoi source.

marker='error: unable to write upstream branch configuration'
tab=$(printf '\t')

input=$(cat) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

output=$(printf '%s' "$input" | jq -r 'del(.tool_input) | .. | strings' 2>/dev/null) || exit 0
persisted=$(printf '%s' "$input" | jq -r '.tool_response.persistedOutputPath? // empty' 2>/dev/null)
if [ -n "$persisted" ] && [ -f "$persisted" ] && [ -r "$persisted" ]; then
  output=$(printf '%s\n' "$output"; tail -c 262144 "$persisted" 2>/dev/null)
fi
output=$(printf '%s\n' "$output" | tr -d '\r')
has() { printf '%s\n' "$output" | grep -Eq -- "$1"; }
has "^$marker\$" || exit 0

event=$(printf '%s' "$input" | jq -r '.hook_event_name // "PostToolUse"' 2>/dev/null)
case "$event" in PostToolUse|PostToolUseFailure) ;; *) event=PostToolUse ;; esac
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

lockline=$(printf '%s\n' "$output" | grep -m 1 '^error: could not lock config file ')
case "$lockline" in
  '') cause=unknown ;;
  *': Operation not permitted') cause=sandbox ;;
  *) cause=other ;;
esac

# git's push report: a "To <url>" line plus ref lines. Human format:
# " * [new branch]  a -> a", "   1a2b..3c4d  a -> a", " + 1a2b...3c4d a -> a",
# " ! [rejected]  a -> a (fetch first)". --porcelain: "<flag>\t<src>:<dst>\t<summary>".
pushed=no
if has '^To ' && has "^ [ *+=-] [^ ].* -> |^[ *+=-]${tab}[^${tab}]*:[^${tab}]*${tab}"; then
  pushed=yes
fi
rejected=no
has "^ ! |^!${tab}|^error: failed to push some refs" && rejected=yes
# Outside the session's repositories the sandbox also blocks refs/remotes, so
# the remote-tracking branch the upstream would point at may not exist yet.
stale=no
has "update_ref failed for ref 'refs/remotes/|cannot lock ref 'refs/remotes/" && stale=yes

fix='git branch --set-upstream-to=<remote>/<branch> <branch>'
msg='追跡設定（upstream）を .git/config に書けなかった（git の「unable to write upstream branch configuration」）。'
case "$cause" in
  sandbox) msg="${msg}原因はサンドボックスで、サンドボックス内からはこのリポジトリの .git/config を書けない。" ;;
  other) msg="${msg}原因は git の出力の「${lockline#error: }」の行にある。" ;;
  *) msg="${msg}原因は git の出力で確かめる。" ;;
esac

if [ "$pushed" = yes ]; then
  if [ "$event" = PostToolUse ] && [ "$rejected" = no ]; then
    msg="${msg}push 自体は成功しているので、push はやり直さない。"
  else
    msg="${msg}push の結果は ref ごとに違うことがある。出力の [new branch]・[rejected] などの行で、送られた ref を確かめてから再 push が要るかを決める。"
  fi
  msg="${msg}PR は gh pr create --head <branch>（fork から送るなら --head <owner>:<branch>）で作れる。"
elif has '^Everything up-to-date$'; then
  msg="${msg}送るものは無かった（Everything up-to-date）ので、push はやり直さない。"
else
  case "$command" in
    *push*)
      msg="${msg}push が行われたかは出力から判断できない。git ls-remote <remote> <branch> で確かめてから、再 push が要るかを決める。"
      ;;
    *'switch -c'*|*'switch -C'*|*'switch --create'*|*'switch --force-create'*|*'checkout -b'*|*'checkout -B'*|*'branch --track'*|*'branch -t'*)
      msg="${msg}ブランチは作られたが、切り替わっていないことがある（git は終了コード 1 を返す）。同じコマンドはやり直さず、git branch --show-current と git branch --list <branch> で確かめ、必要なら git switch <branch> で切り替える。"
      ;;
  esac
fi

case "$cause" in
  sandbox)
    if [ "$stale" = yes ]; then
      msg="${msg}リモート追跡ブランチ（refs/remotes）も更新できていない。追跡設定が要るなら、サンドボックスの外で git fetch <remote> <branch> のあとに ${fix} を実行する"
    else
      msg="${msg}追跡設定が要るなら、サンドボックスの外で ${fix} を実行する"
    fi
    msg="${msg}（そのリポジトリで開いたセッションから git だけでできたコマンド行で実行するか、dangerouslyDisableSandbox を付ける）。以後、git -C を使うときや、git 以外のコマンド・パイプ・ファイルへのリダイレクトを含む行で push するときは、-u を付けず git push origin <branch> を使う（~/.claude/rules/git-workflow.md）。"
    ;;
  other)
    msg="${msg}古い .git/config.lock が残っているならそれを消し、${fix} で追跡設定だけを書く。"
    ;;
  *)
    msg="${msg}追跡設定が要るなら、原因を取り除いてから ${fix} で追跡設定だけを書く。"
    ;;
esac

jq -n --arg e "$event" --arg m "$msg" \
  '{hookSpecificOutput: {hookEventName: $e, additionalContext: $m}}'
exit 0
