# OH-MY-ZSH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(zsh-vi-mode zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

export EDITOR='nvim'
export ZVM_VI_EDITOR="nvim-pager"

# Set up fuzzy finding
source <(fzf --zsh)

# Terminal Prompt configuration (See starship/starship.toml)
eval "$(starship init zsh)"

# VI Mode
bindkey -v

# History
export HISTSIZE=10000000
export SAVEHIST=10000000
setopt HIST_IGNORE_DUPS
setopt INC_APPEND_HISTORY

#~~~~~~~~~~~~~~~~~~~~~~~~
# Autocomplete
#~~~~~~~~~~~~~~~~~~~~~~~~
autoload -U +X compinit && compinit

# Google cloud
if command -v brew &>/dev/null && command -v gcloud &>/dev/null; then
  source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
fi

# ArgoCD
command -v argocd &>/dev/null && source <(argocd completion zsh)

# yq
command -v yq &>/dev/null && yq shell-completion zsh > "${fpath[1]}/_yq"

# kubectl
command -v kubectl &>/dev/null && source <(kubectl completion zsh)

# mise
if command -v mise &>/dev/null; then
  eval "$(/opt/homebrew/bin/mise activate zsh)"
  source <(mise completion zsh)
fi

#~~~~~~~~~~~~~~~~~~~~~~~~

# Dotfile executables
export PATH="$PATH:$HOME/go/bin/"
export PATH="$PATH:$DOTFILE_PATH/bin"
export PATH="$PATH:$DOTFILE_PATH/bin/scripts"

