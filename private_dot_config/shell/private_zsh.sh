============================================
# zsh.sh
# ============================================

# --------------------------------------------
# PATH
# --------------------------------------------
typeset -U PATH path

# --------------------------------------------
# Zsh Options
# --------------------------------------------
setopt auto_cd              
setopt hist_ignore_dups     
setopt hist_reduce_blanks   
setopt hist_save_no_dups    
setopt share_history        
setopt complete_in_word     

# --------------------------------------------
# Completion Settings
# --------------------------------------------
autoload -U +X compinit && compinit

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  
zstyle ':completion:*' menu select                          

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
# Brew File Auto Update Settings
# --------------------------------------------
if command -v brew &> /dev/null; then
    function _update_brewfile() {
        {
            command brew tap
            command brew leaves --installed-on-request | sed 's/^/brew "/' | sed 's/$/"/'
            command brew list --cask -1 | sed 's/^/cask "/' | sed 's/$/"/'
        } > ~/.Brewfile
        echo "Brewfile updated"
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
# Precmd Settings
# --------------------------------------------
precmd() {
  if [ -z "$_FIRST_PROMPT" ]; then
    _FIRST_PROMPT=1
  else
    echo
  fi
}

# --------------------------------------------
# Plugins
# --------------------------------------------
if [ -n "$HOMEBREW_PREFIX" ]; then
    [ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
        source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    [ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
        source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
