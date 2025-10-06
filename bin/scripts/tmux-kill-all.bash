#! /usr/bin/env bash

# Safely closes all tmux sessions, excluding "dotfiles", "scratch", and the
# currently attached session.

tmux_running=$(pgrep tmux)
if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    echo Must run in tmux
    exit 0
fi

# All sessions, excluding the one currently attached
sessions=$(tmux list-sessions | grep -v "attached" | awk '{print $1}' | sed 's/://')

while IFS= read -r session; do
    if [[ $session == "dotfiles" || $session == "scratch" ]]; then
		continue
    fi
    tmux-safe-kill-session-by-name.bash "$session"
done <<< "$sessions"
