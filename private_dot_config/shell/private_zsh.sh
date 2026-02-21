# ============================================
# zsh.sh
# ============================================

# --------------------------------------------
# PATH
# --------------------------------------------
typeset -U path PATH

# --------------------------------------------
# Zsh Options
# --------------------------------------------
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

# --------------------------------------------
# Completion System
# --------------------------------------------
autoload -Uz colors && colors

# fpath setup (before compinit)
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  fpath=($HOMEBREW_PREFIX/share/zsh-completions $fpath)
fi
[[ -d "$HOME/.docker/completions" ]] && fpath=($HOME/.docker/completions $fpath)
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

autoload -Uz compinit && compinit

zstyle ":completion:*:commands" rehash 1
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%F{green}[%d]%f%b'
zstyle ':completion:*:processes' command 'ps -au$USER'

# --------------------------------------------
# Plugins
# --------------------------------------------
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  [[ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Kiro shell integration
[[ "$TERM_PROGRAM" == "kiro" ]] && command -v kiro &>/dev/null && \
  . "$(kiro --locate-shell-integration-path zsh)"

# --------------------------------------------
# Peco
# --------------------------------------------
function peco-select-history() {
    BUFFER=$(fc -l -n 1 | tail -r | awk '!a[$0]++' | peco --query "$LBUFFER")
    CURSOR=${#BUFFER}
}

if command -v peco &> /dev/null; then
    zle -N peco-select-history
    bindkey '^R' peco-select-history
fi

# --------------------------------------------
# Brew Auto Update
# --------------------------------------------
if command -v brew &> /dev/null; then
    function _update_brewfile() {
        {
            command brew tap
            command brew leaves --installed-on-request | sed 's/^/brew "/' | sed 's/$/"/'
            command brew list --cask -1 | sed 's/^/cask "/' | sed 's/$/"/'
        } > ~/.Brewfile
        echo "Brewfile updated"
        if command -v chezmoi &>/dev/null; then
            chezmoi add ~/.Brewfile
            echo "Synced to chezmoi"
        fi
    }

    function brew() {
        command brew "$@"
        local exit_code=$?
        case "$1" in
            install|uninstall|remove|untap)
                [[ $exit_code -eq 0 ]] && _update_brewfile
                ;;
        esac
        return $exit_code
    }
fi

# --------------------------------------------
# Precmd
# --------------------------------------------
precmd() {
  if [ -z "$_FIRST_PROMPT" ]; then
    _FIRST_PROMPT=1
  else
    echo
  fi
}

# --------------------------------------------
# K8s
# --------------------------------------------
if command -v kubectl &>/dev/null; then
  source <(kubectl completion zsh)
  compdef k=kubectl
fi
