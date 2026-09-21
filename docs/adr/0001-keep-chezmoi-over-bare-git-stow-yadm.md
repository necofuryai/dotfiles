---
status: accepted
---

# Keep chezmoi rather than migrate to bare git, GNU Stow or yadm

This public dotfiles repository is small (about 30 files, one macOS machine,
zsh only), and its one real pain, a hand-merge on `~/.claude/settings.json`,
raised the question of whether plain git, GNU Stow or yadm would be simpler.
We keep chezmoi because it is the only option that records file modes
declaratively (`executable_`, `private_`) and renders outside the repository,
which keeps the absolute home path out of public commits by construction
rather than by detector. The settings.json pain was a template problem, not a
chezmoi problem: `chezmoi re-add` is a silent no-op on templated targets, and
dropping that template in favor of `~/` paths (commit 95939a8) removed the
hand-merge.

## Considered Options

- **Bare git in `$HOME`**: git records only the executable bit, so a fresh
  clone lands `private_` files as 0644 and the mode-fixing hook is itself not
  cloned; `git clean -fdx` would also wipe `$HOME`.
- **GNU Stow (symlink farm)**: tree folding links whole directories into the
  package, so app-written state lands in the public repo unless `--no-folding`
  is never forgotten; `stow -n` previews link operations, not content, and
  whether apps that save via atomic rename replace the symlink was never tested.
- **yadm**: bare git underneath, so the same mode loss applies; every
  pass-through git command, `yadm status` included, re-renders its templates
  over the target with no prompt.
- **nix / home-manager**: out of proportion to 30 files on one machine.

## Consequences

- The hazards that made chezmoi feel unsafe are real and are now guarded in the
  repository rather than in memory: the gitleaks rule matches a home path even
  without a trailing slash (commit 7214c97); the
  `~/.claude/hooks/chezmoi-guard.sh` PreToolUse hook blocks `add` with
  `-T/--template`, `-a/--autotemplate` or `--force`, and `--force` on `apply`,
  `update` and `--apply`; and CLAUDE.md documents the `status` ambiguity
  (measurements for the last two in commit 61de22a).
- One template remains, `private_Library/LaunchAgents/*.plist.tmpl`, because
  launchd does not expand `~`. `chezmoi re-add` is a silent no-op on it, so it
  is edited by hand.
- A fresh-clone bootstrap (the README's three lines) has only been
  syntax-checked, not run on a second machine.
