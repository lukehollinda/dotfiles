#!/usr/bin/env bash
# Close every tmux session except "dotfiles", "scratch", and the attached one.

source "$(command -v tmux-common.bash)"
tmux_require_server

while IFS= read -r session; do
    case "$session" in
        dotfiles | scratch) continue ;;
    esac
    tmux-safe-kill-session-by-name.bash "$session"
done < <(tmux_detached_session_names)
