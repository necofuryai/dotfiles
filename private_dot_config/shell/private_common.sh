# ============================================
# Homebrew/Linuxbrew Initialization
# ============================================
# Detect OS and initialize Homebrew/Linuxbrew
case "$(uname -s)" in
  Darwin)
    # macOS Homebrew (Apple Silicon only)
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    ;;
  Linux)
    # Linuxbrew
    if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    ;;
esac

# Set BREW_PREFIX for later use
if type brew &>/dev/null; then
  export BREW_PREFIX="$(brew --prefix)"
fi

# ============================================
# Environment Variables
# ============================================
export LANG=en_US.UTF-8
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zsh_history
export MANPAGER="col -b -x|vim -R -c 'set ft=man nolist nomod noma' -"
export GPG_TTY=$(tty)

# Volta
export VOLTA_HOME="$HOME/.volta"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"

# ============================================
# PATH Configuration
# ============================================
# Note: Homebrew paths are already set by 'brew shellenv' above

path=(
  $VOLTA_HOME/bin
  $PNPM_HOME
  $HOME/.bun/bin
  $path              # Homebrewなど既存のパスを先に配置
  /usr/bin          # システム標準は後に
  /usr/sbin
  /bin
  /sbin
  /Library/Apple/usr/bin
)

# ============================================
# Functions
# ============================================
tgz() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: tgz DIST SOURCE"
    return 1
  fi
  xattr -rc "${@:2}" && \
  env COPYFILE_DISABLE=1 tar zcvf "$1" --exclude=".DS_Store" "${@:2}"
}

# ============================================
# Aliases
# ============================================
# Python (prefer Homebrew if available)
if [[ -n "$BREW_PREFIX" ]] && [[ -x "$BREW_PREFIX/bin/python3.11" ]]; then
  alias python="$BREW_PREFIX/bin/python3.11"
  alias pip="$BREW_PREFIX/bin/pip3.11"
else
  alias python="/usr/bin/python3"
  alias pip="/usr/bin/pip3"
fi

# File listing (eza > ls)
if command -v eza &>/dev/null; then
  alias ls='eza --group-directories-first'
  alias tree='eza --tree'
else
  alias ls='ls -G'
fi

# Kubernetes
alias k=kubectl

# ============================================
# Starship Prompt
# ============================================
command -v starship &>/dev/null && eval "$(starship init zsh)"
