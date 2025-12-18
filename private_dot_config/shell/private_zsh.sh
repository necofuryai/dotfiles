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

# peco

function peco-select-history() {
    BUFFER=$(fc -l -n 1 | tail -r | awk '!a[$0]++' | peco --query "$LBUFFER")
    CURSOR=${#BUFFER}
}

if command -v peco &> /dev/null; then
    zle -N peco-select-history
    bindkey '^R' peco-select-history
fi

# --------------------------------------------
# brew Auto Update
# --------------------------------------------
if command -v brew &> /dev/null; then
    function brew() {
        command brew "$@"
        local exit_code=$?

        case "$1" in
            install|uninstall|remove)
                if [[ $exit_code -eq 0 ]]; then
                    echo "Update Brewfile..."
                    command brew bundle dump --file=~/.Brewfile --force
                    if command -v chezmoi &>/dev/null; then
                        chezmoi add ~/.Brewfile
                        echo "Add/Delete for chezmoi"
                    fi
                fi
                ;;
        esac

        return $exit_code
    }
fi

# --------------------------------------------
# K8s Complementary Settings
# --------------------------------------------
source <(kubectl completion zsh)
compdef k=kubectl
