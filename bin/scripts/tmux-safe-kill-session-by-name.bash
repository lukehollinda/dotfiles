#!/usr/bin/env bash
# Close the tmux session named $1, quitting nvim first.
#
# Killing a session out from under nvim leaves its LSP servers running as
# orphans, so each nvim is asked to quit. A session holding unsaved buffers is
# left open.

SESSION="$1"
if [[ -z "$SESSION" ]]; then
    echo "Expected session name as script argument" >&2
    exit 1
fi

if ! tmux has-session -t="$SESSION" 2>/dev/null; then
    echo "Session '$SESSION' does not exist." >&2
    exit 1
fi

nvim_panes=$(tmux list-panes -s -t "$SESSION" -F '#{window_id} #{pane_id}' \
    -f '#{m:*nvim*,#{pane_current_command}}')

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

# Have each nvim write out its count of modified buffers, and abort if any has one.
while read -r window_id pane_id; do
    [[ -z "$pane_id" ]] && continue

    # Clear the previous pane's count so it cannot be read as this pane's
    : > "$tmpfile"

    # Escape first so the command line is reached from normal mode.
    tmux send-keys -t "$SESSION:$window_id.$pane_id" Escape
    tmux send-keys -t "$SESSION:$window_id.$pane_id" \
        ":call writefile([len(filter(getbufinfo(), 'v:val.changed'))], '$tmpfile')" Enter
    sleep 0.2

    unsaved=$(cat "$tmpfile")
    if (( ${unsaved:-0} > 0 )); then
        message="Unsaved changes in nvim in window $window_id, pane $pane_id. Aborting close of session $SESSION."
        tmux display-popup "echo '$message'"
        echo "$message" >&2
        exit 1
    fi
done <<< "$nvim_panes"

while read -r window_id pane_id; do
    [[ -z "$pane_id" ]] && continue
    tmux send-keys -t "$SESSION:$window_id.$pane_id" ":qa" Enter
done <<< "$nvim_panes"

# Close the tmux session. Quitting nvim can close the last pane, and the session
# with it, so a failed kill only matters if the session is still there.
tmux kill-session -t "$SESSION" 2>/dev/null

if tmux has-session -t="$SESSION" 2>/dev/null; then
    echo "Failed to close session '$SESSION'." >&2
    exit 1
fi
