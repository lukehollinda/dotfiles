# Dump tmux pane, stripping trailing whitespace
tmuxcapturepane () {
	tmux capture-pane -p -JS -5000 \
	| awk '{ if (NF || !trailing) print $0; if (NF) trailing = 0; else trailing = 1 }'

}

# Dump tmux pane to nvim pager
tmuxtovim () {
	tmuxcapturepane \
	| nvim-pager -R "+set nowrap" "+norm G"
}

# Bind the above function to Ctr-v
zle -N tmuxtovim{,}
bindkey ^v tmuxtovim
