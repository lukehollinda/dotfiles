#!/usr/bin/env bash
# Smart tmux launcher. Use instead of bare `tmux` to avoid unnamed bootstrap sessions.
#
# - If already inside tmux: exits with a message.
# - If server is running: reattaches to the most recently used session from history.
# - If no server: starts tmux and immediately opens the project picker. After the
#   sessionizer switches to a project session, the bootstrap session auto-kills itself.

TMUX_SESSION_HISTORY="$HOME/.tmux/session_history"

if [[ -n "$TMUX" ]]; then
    echo "Already inside a tmux session." >&2
    exit 1
fi

if tmux has-session 2>/dev/null; then
    # Server running - reattach to the most recently used session
    last=$(head -n1 "$TMUX_SESSION_HISTORY" 2>/dev/null)
    if [[ -n "$last" ]] && tmux has-session -t "$last" 2>/dev/null; then
        exec tmux attach-session -t "$last"
    else
        exec tmux attach-session
    fi
else
    # No server - start tmux with a normal shell, then immediately send the sessionizer
    # command to it. fzf --tmux requires a proper interactive shell context; running the
    # script directly as a startup command bypasses that.
    # After switch-client fires, the shell runs `exit`, the bootstrap session closes, and
    # detach-on-destroy off (tmux.conf) keeps the client on the chosen project session.
    exec tmux new-session \; send-keys "tmux-sessionizer.bash" Enter
fi
