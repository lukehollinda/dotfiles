#! /usr/bin/env bash

session=$(tmux display-message -p '#S')

tmux_running=$(pgrep tmux)
if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    echo Must run in tmux
    exit 0
fi

tmux-safe-kill-session-by-name.bash "$session"
