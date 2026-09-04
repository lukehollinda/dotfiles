#!/usr/bin/env bash
# Smart tmux launcher, used instead of bare `tmux`.
#
# - If already inside tmux: exits with a message.
# - If server is running: reattaches to the most recently used session from history.
# - If no server: runs the project picker in the terminal, then attaches to the chosen
#   session. No tmux server is started until a project is picked, so cancelling the
#   picker leaves nothing behind.

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
    # No server - the sessionizer detects it is outside tmux, picks a project with a
    # plain (non-popup) fzf, creates that session and attaches to it directly.
    exec tmux-sessionizer.bash
fi
