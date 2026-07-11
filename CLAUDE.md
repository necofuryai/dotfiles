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
  (README.md, LICENSE, and this file are ignored there). Keep it that way when
  adding repo-level docs.

## Verify changes

```sh
chezmoi diff          # review what apply would do
chezmoi apply         # then confirm chezmoi status is empty
zsh -i -c exit        # a fresh shell must start silently (~0.1s)
```

## Environment facts

- macOS-only, zsh-only, Apple Silicon. Runtimes (bun/node/go/ruby) are managed by
  mise — goenv and rbenv were removed in 2026-07.
- Saving `~/.zshrc`, `~/.vimrc`, `~/.textlintrc`, or `~/.Brewfile` in vim auto-runs
  `chezmoi re-add` (hook in `dot_vimrc`).
