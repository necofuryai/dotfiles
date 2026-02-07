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
export GPG_TTY=$(tty)

# MANPAGER
if command -v nvim &> /dev/null; then
    export MANPAGER="nvim +Man!"
else
    export MANPAGER="col -b -x|vim -R -c 'set ft=man nolist nomod noma' -"
fi

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
  $path
  /usr/bin
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
    if [ "$(uname)" = "Darwin" ]; then
        alias ls='ls -G'
    else
        alias ls='ls --color=auto'
    fi
fi

alias grep='grep --color=auto'

# Neovim
if command -v nvim &> /dev/null; then
    alias vim='nvim'
    alias vi='nvim'
fi

# Prompts
setopt prompt_subst

_git_prompt_info() {
    git rev-parse --git-dir >/dev/null 2>&1 || return

    local branch=$(git branch --show-current 2>/dev/null || echo "detached")
    local status_output=$(git --no-optional-locks status --porcelain 2>/dev/null)

    local modified=$(echo "$status_output" | grep -c "^ M" || true)
    local added=$(echo "$status_output" | grep -c "^A" || true)
    local deleted=$(echo "$status_output" | grep -c "^D" || true)
    local untracked=$(echo "$status_output" | grep -c "^??" || true)

    local ahead_behind=$(git --no-optional-locks rev-list --left-right --count HEAD...@{upstream} 2>/dev/null || echo "0 0")
    local ahead=$(echo "$ahead_behind" | awk '{print $1}')
    local behind=$(echo "$ahead_behind" | awk '{print $2}')

    local git_status=""
    [[ $modified -gt 0 ]] && git_status="${git_status}~${modified}"
    [[ $added -gt 0 ]] && git_status="${git_status}+${added}"
    [[ $deleted -gt 0 ]] && git_status="${git_status}x${deleted}"
    [[ $untracked -gt 0 ]] && git_status="${git_status}?${untracked}"
    [[ $ahead -gt 0 ]] && git_status="${git_status}>${ahead}"
    [[ $behind -gt 0 ]] && git_status="${git_status}<${behind}"

    if [[ -n "$git_status" ]]; then
        printf " %%F{green}git%%f %%F{yellow}%s%%f %%F{red}[%s]%%f" "$branch" "$git_status"
    else
        printf " %%F{green}git%%f %%F{yellow}%s%%f" "$branch"
    fi
}

PROMPT='%F{cyan}%~%f$(_git_prompt_info)
❯ '

# Kubernetes
alias k=kubectl

# ============================================
# Starship Prompt
# ============================================
command -v starship &>/dev/null && eval "$(starship init zsh)"
