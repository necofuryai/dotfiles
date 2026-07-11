# dotfiles

Personal macOS configuration, managed with [chezmoi](https://www.chezmoi.io/).

## Setup

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply necofuryai
brew bundle install --file="$HOME/.Brewfile"
```

## Layout

- `~/.zshenv` — Keychain-backed secrets, mise shims, minimal PATH (read by every zsh)
- `~/.zprofile` — Homebrew shellenv, OrbStack (login shells)
- `~/.zshrc` — single consolidated interactive config: completions via Homebrew
  site-functions, plugins, starship prompt, and the `brew` wrapper that keeps
  `~/.Brewfile` in sync
- `~/.config/shell/secrets.zsh` — loads API keys from the macOS Keychain;
  no plaintext secrets live in this repository
- Editor & app configs — vim/nvim, Zed, Ghostty, git, mise, starship, textlint

Runtimes (bun, node, go, ruby) are managed by [mise](https://mise.jdx.dev/).
Saving `~/.zshrc`, `~/.vimrc`, `~/.textlintrc`, or `~/.Brewfile` in vim runs
`chezmoi re-add` automatically.
