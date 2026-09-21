# CLAUDE.md

This is a **chezmoi source directory** — files here are the source of truth for
`$HOME`, not the live config.

## The source/target split (most important)

- Editing a source file here (e.g. `dot_zshrc`) changes nothing until `chezmoi apply`.
- Editing a target file (e.g. `~/.zshrc`) is lost on the next apply unless you run
  `chezmoi re-add <target>` first.
- Check drift before and after any change: `chezmoi status` (empty = in sync).

## Hard rules

- **This repo is public.** Never commit secrets. API keys are loaded from the macOS
  Keychain by `private_dot_config/shell/private_secrets.zsh`; scan the diff for
  credentials before every commit.
- **`dot_Brewfile` is generated.** The `brew` shell wrapper in `.zshrc` regenerates
  it with `brew bundle dump` after install/uninstall/tap. Don't hand-edit it —
  change the installed packages instead.
- Files at the repo root deploy into `$HOME` unless listed in `.chezmoiignore`
  (README.md, LICENSE, THIRD-PARTY-LICENSES.md, `.agents/` and this file are
  ignored there). Keep it that way when adding repo-level docs.
- **Never run `chezmoi apply --force`.** Plain `apply` prompts when a target has
  drifted; `--force` overwrites it with no prompt and no output. On
  `~/.claude/settings.json` that silently discards permission approvals Claude
  Code wrote. At the drift prompt answer `skip`, not `overwrite`.
- **Never run `chezmoi add` on a templated target.** `chezmoi add --template`
  replaces the `.tmpl` body with rendered literals — exit 0, no prompt, no
  warning — baking an absolute home path into this public repo. Edit the
  `.tmpl` by hand instead. Plain `chezmoi add` on a template prompts first and
  fails safely in a non-TTY, so `--template` and `--force` are the dangerous
  forms. This rule is the guard, not a permission deny: `chezmoi add` is
  allowed, because on a non-templated target it infers the `private_` and
  `executable_` prefixes from the live file mode, which a plain `cp` into the
  source tree silently loses — and a 0600 secret copied that way is applied
  back as 0644. The pre-commit gitleaks hook is the backstop that catches the
  home path if the dangerous form is ever run.

## Verify changes

```sh
chezmoi status        # drift check FIRST — see the table below before applying
chezmoi diff          # review what apply would do
chezmoi apply         # then confirm chezmoi status is empty
zsh -i -c exit        # a fresh shell must start silently (~0.1s)
```

`chezmoi status` cannot tell you which side moved, so read it with this table
(verified on v2.72.2):

| output | meaning |
| --- | --- |
| `MM <path>` | the target drifted — **or** both sides did. Ambiguous. |
| ` M <path>` | only the source changed; `apply` is safe. |
| empty | in sync. |

Because `MM` covers both cases, never take it as "safe to overwrite the source".
Ask git instead — `git diff HEAD -- "$(chezmoi source-path <target>)"` is the
only reliable answer to "did I edit the source and not apply it yet?".

## Environment facts

- macOS-only, zsh-only, Apple Silicon. Runtimes (bun/node/go/ruby) are managed by
  mise — goenv and rbenv were removed in 2026-07.
- Saving `~/.zshrc`, `~/.vimrc`, `~/.textlintrc`, or `~/.Brewfile` in vim auto-runs
  `chezmoi re-add` (hook in `dot_vimrc`).
