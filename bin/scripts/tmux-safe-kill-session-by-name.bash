#! /usr/bin/env bash


# Safely close tmux session by session name.

# This was written because closing tmux sessions or windows with nvim running
# was leading to build up of orphaned LSP processes.

# $1 = session name
if [[ -z "$1" ]]; then
	echo "Expected session name as script argument"
	exit 1
fi

SESSION="$1"

## Check if session exists
if ! tmux has-session -t="$SESSION" 2> /dev/null; then
	echo "Session '$SESSION' does not exist."
	exit 1
fi

## nvim panes session
nvim_panes=$(tmux list-panes -s -t "$SESSION" -F "#{window_id} #{pane_id} #{pane_current_command}" | grep nvim)

## Check if any nvim instances have unsaved changes
while read -r pane; do
	window_id=$(echo "$pane" | awk '{print $1}')
	pane_id=$(echo "$pane" | awk '{print $2}')

	tmpfile=$(mktemp)
	trap 'rm -f "$tmpfile"' RETURN

	# Make sure we're in normal mode
	tmux send-keys -t "$SESSION:$window_id.$pane_id" Escape

	# Have nvim count if there are unsaved buffers. Send to temp file.
	tmux send-keys -t "$SESSION:$window_id.$pane_id" ":call writefile([len(filter(getbufinfo(), 'v:val.changed'))], '$tmpfile')" Enter

	sleep 0.1

	if [[ $(cat "$tmpfile") -gt 0 ]]; then
		tmux display-popup "echo 'Unsaved changes in nvim in window $window_id, pane $pane_id. Aborting close of session $SESSION.'"
		echo "Unsaved changes in nvim in window $window_id, pane $pane_id"
		echo "Aborting close of session $SESSION"
		exit 1
	fi
done <<< "$nvim_panes"

# Close all nvim instances
while read -r pane; do
	window_id=$(echo "$pane" | awk '{print $1}')
	pane_id=$(echo "$pane" | awk '{print $2}')
	tmux send-keys -t "$SESSION:$window_id.$pane_id" ":qa" Enter
done <<< "$nvim_panes"

# Close the tmux session
tmux kill-session -t "$SESSION"

exit 0
