#! /usr/bin/env bash

# $1 = session closed name
# It appears that we must pass the closed session name as an argument. Attempting
# to display the session name here will return the session which is opened after
# close.

TMUX_SESSION_HISTORY="$HOME/.tmux/session_history"

# Get current tmux session
current_session="$1"

# Remove from session history
sed -i '' "/^$current_session$/d" "$TMUX_SESSION_HISTORY"

# Switch to previous session
previous_session=$(head -n 1 "$TMUX_SESSION_HISTORY")
if [[ -z $previous_session ]]; then
	echo "No previous session found."
	exit 1
fi
tmux switch-client -t "$previous_session"

exit 0
