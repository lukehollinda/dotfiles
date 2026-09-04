#!/usr/bin/env bash
# Shared helpers for the tmux session management scripts.
# Sourced, not executed: source "$(command -v tmux-common.bash)"

# Exit unless a tmux server is reachable, either from inside a session or from a
# shell outside one.
tmux_require_server() {
    [[ -n "$TMUX" ]] && return 0
    tmux has-session 2>/dev/null && return 0
    echo "No tmux server running" >&2
    exit 1
}

# Print every session name, one per line.
tmux_session_names() {
    tmux list-sessions -F '#{session_name}' 2>/dev/null
}

# Print every session name except the attached one.
tmux_detached_session_names() {
    tmux list-sessions -f '#{==:#{session_attached},0}' -F '#{session_name}' 2>/dev/null
}
