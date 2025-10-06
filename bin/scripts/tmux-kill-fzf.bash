#! /usr/bin/env bash

selected=$(tmux list-sessions | awk '{print $1}' | sed 's/://' | fzf)

if [[ -z $selected ]]; then
    exit 0
fi

tmux_running=$(pgrep tmux)
if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    echo Must run in tmux
    exit 0
fi

tmux-safe-kill-session-by-name.bash "$selected"
