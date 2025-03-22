# OH-MY-ZSH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=()
source $ZSH/oh-my-zsh.sh


# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi


# Set up fuzzy finding
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Add starship to terminal. (PS1 prompt for K8s)
eval "$(starship init zsh)"

# Google cloud autocomplete and path 
source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"


# ZSH Vim Mode plugin
source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
export ZVM_VI_EDITOR=nvim

# VI Mode, potentially needs to be called after atuin init
bindkey -v

