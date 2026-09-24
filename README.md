# dotfiles

Personal macOS configuration, managed with [chezmoi](https://www.chezmoi.io/).

## Setup

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply necofuryai
brew bundle install --file="$HOME/.Brewfile"
(cd "$(chezmoi source-path)" && uvx pre-commit install)
```

The third line is not optional. Git hooks are not cloned, so a fresh machine has
no local gitleaks gate — without it the first commit reaches this public
repository checked only by post-push CI.

Commits and tags are GPG-signed (`commit.gpgsign` in `dot_gitconfig`), and the
secret key is not in this repository. Import it with `gpg --import` before the
first commit; `pinentry-mac` from the Brewfile and the managed
`~/.gnupg/gpg-agent.conf` handle the passphrase prompt.

## Layout

- `~/.zshenv` — Keychain-backed secrets, mise shims, minimal PATH (read by every zsh)
- `~/.zprofile` — Homebrew shellenv, mise shims (login shells)
- `~/.zshrc` — single consolidated interactive config: completions via Homebrew
  site-functions, plugins, starship prompt, and the `brew` wrapper that keeps
  `~/.Brewfile` in sync
- `~/.config/shell/secrets.zsh` — loads API keys from the macOS Keychain;
  no plaintext secrets live in this repository
- Editor & app configs — vim/nvim, Zed, git, mise, starship, textlint

Runtimes (bun, node, go, ruby) are managed by [mise](https://mise.jdx.dev/).
Saving `~/.zshrc`, `~/.vimrc`, `~/.textlintrc`, or `~/.Brewfile` in vim runs
`chezmoi re-add` automatically; if source and target are still out of sync
afterwards it raises an error, which also cancels a `:wq` so the message is
not lost.
