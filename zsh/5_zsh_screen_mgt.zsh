# Print this pane's scrollback with wrapped lines joined: from Rex inside Rex,
# from tmux otherwise.
capturepane () {
	if [[ -n $REX_BLOCK ]]; then
		rex capture --unwrap
	else
		tmux capture-pane -p -JS -
	fi
}

# The same, keeping the colour escapes.
capturepanecolour () {
	if [[ -n $REX_BLOCK ]]; then
		rex capture --unwrap --format=vt
	else
		tmux capture-pane -e -p -JS -
	fi
}

# Dump the pane to the nvim pager. tmux pads joined lines with trailing
# whitespace, so strip it; runs of blank lines collapse to one.
panetovim () {
	capturepane \
	| awk '{ sub(/[[:space:]]+$/, ""); if (NF || !blank) print; blank = (NF == 0) }' \
	| nvim-pager -R "+set nowrap" "+norm G"
}

# Dump the pane in colour. Joined lines are the only place the logical line
# boundaries survive; render_ansi sizes its grid to them and strips the
# trailing whitespace tmux leaves behind.
panecolourtovim () {
	capturepanecolour \
	| nvim-pager -R "+lua require('pager').render_ansi()"
}

# Colour is the primary view; the uncoloured one is the fallback when the
# terminal rendering misbehaves.
zle -N panecolourtovim
bindkey ^v panecolourtovim

zle -N panetovim
bindkey ^g panetovim
