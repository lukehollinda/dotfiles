#! /usr/bin/env bash


# Close the tmux session named $1, quitting nvim first.
#
# Killing a session out from under nvim leaves its LSP servers running as
# orphans, so each nvim is asked to quit. A session holding unsaved buffers is
# left open.
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

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

## Check if any nvim instances have unsaved changes
while read -r pane; do
	window_id=$(echo "$pane" | awk '{print $1}')
	pane_id=$(echo "$pane" | awk '{print $2}')

	# Clear the previous pane's count so it cannot be read as this pane's
	: > "$tmpfile"

	# Make sure we're in normal mode
	tmux send-keys -t "$SESSION:$window_id.$pane_id" Escape

	# Have nvim count if there are unsaved buffers. Send to temp file.
	tmux send-keys -t "$SESSION:$window_id.$pane_id" ":call writefile([len(filter(getbufinfo(), 'v:val.changed'))], '$tmpfile')" Enter

	sleep 0.2

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

# Close the tmux session. Quitting nvim can close the last pane, and the session
# with it, so a failed kill only matters if the session is still there.
tmux kill-session -t "$SESSION" 2> /dev/null

if tmux has-session -t="$SESSION" 2> /dev/null; then
	echo "Failed to close session '$SESSION'." >&2
	exit 1
fi
