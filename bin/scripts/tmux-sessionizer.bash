#!/usr/bin/env bash
# Interactive tmux session picker for switching between project directories.
#
# With no argument, fzf lists every git repo under SESSION_PICKER_DIRECTORIES and
# switches to that project's session, creating it if necessary. With "previous",
# switches back to the session used before the current one. With a directory
# path, switches straight to that project's session.
#
# Runs both inside and outside tmux. Outside tmux it renders fzf in the terminal
# and attaches to the chosen session, so no throwaway bootstrap session is needed.
#
# Session history is tracked by the on-session-* hook scripts in this folder.

SESSION_PICKER_DIRECTORIES=(
    "$HOME"
    "$HOME/work"
    "$HOME/person"
    "$HOME/person/dev"
    "$HOME/upstream"
)

TMUX_SESSION_HISTORY="${TMUX_SESSION_HISTORY:-$HOME/.tmux/session_history}"

# Print the picked project, as a path relative to $HOME.
select-project() {
    # --tmux renders fzf in a popup, which requires a surrounding tmux client
    local fzf_args=()
    [[ -n $TMUX ]] && fzf_args+=(--tmux)

    find "${SESSION_PICKER_DIRECTORIES[@]}" -mindepth 2 -maxdepth 2 -type d -name ".git" 2>/dev/null \
        | sed -e 's|/\.git$||' -e "s|^$HOME/||" \
        | fzf "${fzf_args[@]}"
}

# $1 = session name
goto-session() {
    if [[ -n $TMUX ]]; then
        tmux switch-client -t "$1"
    else
        exec tmux attach-session -t "$1"
    fi
}

# $1 = full path to the project.
switch-session() {
    local name
    name=$(basename "$1" | tr . _)

    if ! tmux has-session -t="$name" 2>/dev/null; then
        tmux new-session -ds "$name" -c "$1"
        # scratch is a bare shell; other projects open an editor plus a terminal window.
        if [[ "$name" != "scratch" ]]; then
            tmux send-keys -t "$name" 'nvim .' C-m
            tmux new-window -dt "$name" -n term -c "$1"
        fi
    fi

    goto-session "$name"
}

case "${1:-}" in
    "")
        selected=$(select-project)
        [[ -z "$selected" ]] && exit 0
        switch-session "$HOME/$selected"
        ;;
    previous)
        previous_session=$(sed -n '2p' "$TMUX_SESSION_HISTORY" 2>/dev/null)
        [[ -z "$previous_session" ]] && exit 1
        goto-session "$previous_session"
        ;;
    *)
        if [[ ! -d "$1" ]]; then
            echo "Not a project directory: $1" >&2
            exit 1
        fi
        switch-session "$1"
        ;;
esac
