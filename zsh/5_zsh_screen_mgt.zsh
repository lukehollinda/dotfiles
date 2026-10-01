# Dump tmux pane. -J pads wrapped lines with trailing whitespace, so strip it;
# runs of blank lines collapse to one.
tmuxcapturepane () {
	tmux capture-pane -p -JS - \
	| awk '{ sub(/[[:space:]]+$/, ""); if (NF || !blank) print; blank = (NF == 0) }'
}

# Dump tmux pane to nvim pager
tmuxtovim () {
	tmuxcapturepane \
	| nvim-pager -R "+set nowrap" "+norm G"
}

# Bind the above function to Ctr-v
zle -N tmuxtovim
bindkey ^v tmuxtovim
