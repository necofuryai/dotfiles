# ============================================
# Zsh Options
# ============================================
setopt auto_cd
setopt auto_menu
setopt auto_list
setopt list_packed
setopt hist_ignore_dups
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt share_history
setopt complete_in_word
setopt nonomatch
setopt RM_STAR_SILENT

ZLE_REMOVE_SUFFIX_CHARS=$''

# ============================================
# PATH Configuration
# ============================================
typeset -U path PATH

# ============================================
# Completion System
# ============================================
autoload -Uz colors && colors

# fpath setup (before compinit)
if [[ -n "$BREW_PREFIX" ]]; then
  fpath=($BREW_PREFIX/share/zsh-completions $fpath)
fi

# Docker CLI completions
[[ -d "$HOME/.docker/completions" ]] && fpath=($HOME/.docker/completions $fpath)

# Bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# Initialize completion system (once!)
autoload -Uz compinit && compinit

# Completion styles
zstyle ":completion:*:commands" rehash 1
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%F{green}[%d]%f%b'
zstyle ':completion:*:processes' command 'ps -au$USER'

# ============================================
# Plugins & Tools
# ============================================
if [[ -n "$BREW_PREFIX" ]]; then
  [[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Kiro shell integration
[[ "$TERM_PROGRAM" == "kiro" ]] && command -v kiro &>/dev/null && \
  . "$(kiro --locate-shell-integration-path zsh)"
