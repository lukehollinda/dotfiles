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

# Dump tmux pane in colour. -J is omitted because nvim_open_term reflows to the
# window width anyway, and without it tmux strips trailing whitespace itself.
tmuxcolourtovim () {
	tmux capture-pane -e -p -S - \
	| nvim-pager -R "+lua require('pager').render_ansi()"
}

# Colour is the primary view; the uncoloured one is the fallback when the
# terminal rendering misbehaves.
zle -N tmuxcolourtovim
bindkey ^v tmuxcolourtovim

zle -N tmuxtovim
bindkey ^g tmuxtovim
