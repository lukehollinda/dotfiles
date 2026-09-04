#!/usr/bin/env bash
# Close the attached tmux session.

# shellcheck source=SCRIPTDIR/tmux-common.bash
source "$(command -v tmux-common.bash)"
tmux_require_server

tmux-safe-kill-session-by-name.bash "$(tmux display-message -p '#S')"
