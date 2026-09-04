#!/usr/bin/env bash
# Pick a tmux session with fzf and close it.

# shellcheck source=SCRIPTDIR/tmux-common.bash
source "$(command -v tmux-common.bash)"
tmux_require_server

selected=$(tmux_session_names | fzf)
[[ -z "$selected" ]] && exit 0

tmux-safe-kill-session-by-name.bash "$selected"
