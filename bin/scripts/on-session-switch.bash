#! /usr/bin/env bash

TMUX_SESSION_HISTORY="$HOME/.tmux/session_history"

if [[ ! -f $TMUX_SESSION_HISTORY ]]; then
	touch "$TMUX_SESSION_HISTORY"
fi

# Get current tmux session
current_session=$(tmux display-message -p '#S')

# Remove any duplicates from the session history
sed -i '' "/^$current_session$/d" "$TMUX_SESSION_HISTORY"

# Add the current session to the top of the history
echo "$current_session" | cat - "$TMUX_SESSION_HISTORY" > temp && mv temp "$TMUX_SESSION_HISTORY"

# Limit the history to the last 10 sessions
sed -I '11,$d' "$TMUX_SESSION_HISTORY"

exit 0
