#!/usr/bin/env bash
# Close the attached tmux session.

source "$(command -v tmux-common.bash)"
tmux_require_server

tmux-safe-kill-session-by-name.bash "$(tmux display-message -p '#S')"
