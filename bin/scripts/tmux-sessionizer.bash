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
select-project() {
    # --tmux renders fzf in a popup, which requires a surrounding tmux client
    local fzf_args=()
    [[ -n $TMUX ]] && fzf_args+=(--tmux)

    find "${SESSION_PICKER_DIRECTORIES[@]}" -mindepth 2 -maxdepth 2 -type d -name ".git" 2>/dev/null \
        | sed 's|/\.git$||' \
        | sed "s|^$HOME/||" \
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

# $1 = full path
switch-session() {
    # Switch to new session, creating if necessary
    selected_name=$(basename "$1" | tr . _)
    if ! tmux has-session -t="$selected_name" 2> /dev/null; then
        create-new-session "$selected_name" "$1"
    fi
    goto-session "$selected_name"
}

# $1 = name, $2 = full path
create-new-session() {
    # scratch is a bare shell; other projects open an editor plus a terminal window.
    if [[ $1 == "scratch" ]]; then
        tmux new-session -ds "$1" -c "$2"
        return
    fi
    tmux new-session -ds "$1" -c "$2"
    tmux send-keys -t "$1" 'nvim .' C-m
    tmux new-window -dt "$1" -n term -c "$2"
}

if [[ -z "$1" ]]; then # Use picker
    selected=$(select-project)
    if [[ -z $selected ]]; then
        exit 0
    fi
    switch-session "${HOME}/${selected}"
elif [[ "$1" == "previous" ]]; then # Switch to previous session
    previous_session=$(head -n 2 "$TMUX_SESSION_HISTORY" | tail -n 1)
    if [[ -z $previous_session ]]; then
        exit 1
    fi
    goto-session "$previous_session"

elif [[ -d "$1" ]]; then # Switch to the session for a project path

    switch-session "$1"
fi
