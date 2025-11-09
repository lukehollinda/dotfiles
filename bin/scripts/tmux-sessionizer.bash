#!/usr/bin/env bash

# Interactive tmux session picker for quickly switching between project directories.

# Uses fzf to show you all git directories within a defined list of directories.
# Switches you to the selected session, creating it if necessary.
# Keeps track of your last sessiong allowing you to quickly switch back to it.

tmux_running=$(pgrep tmux)
if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    echo "Please run from inside tmux"
    exit 0
fi

SESSION_PICKER_DIRECTORIES=(
    "$HOME"
    "$HOME/work"
    "$HOME/work/dev"
    "$HOME/work/upstream"
    "$HOME/person"
    "$HOME/person/dev"
    "$HOME/person/upstream"
    "$HOME/person/upstream/golang-resources"
    "$HOME/person/upstream/system-design-resources"
    "$HOME/person/upstream/leetcode-resources"
)

TMUX_SESSION_HISTORY="$HOME/.tmux/session_history"
select-project() {
    find "${SESSION_PICKER_DIRECTORIES[@]}" -mindepth 2 -maxdepth 2 -type d -name ".git" \
        | sed 's|/\.git$||' \
        | sed "s|^$HOME/||" \
        | fzf
}

# TODO: Find a way to save previous session when swiching sessions without using
#       this script
# $1 = full path
switch-session() {
    # Switch to new session, creating if necessary
    selected_name=$(basename "$1" | tr . _)
    if ! tmux has-session -t="$selected_name" 2> /dev/null; then
        create-new-session "$selected_name" "$1"
    fi
    tmux switch-client -t "$selected_name"
}

# $1 = name, $2 = full path
create-new-session() {
    tmux new-session -ds "$1" -c "$2"
    tmux send-keys -t "$1" 'nvim .' C-m
    tmux new-window -dt "$1" -n term -c "$2"
}

if [[ -z "$1" ]]; then
    # Use picker
    selected=$(select-project)
    if [[ -z $selected ]]; then
        exit 0
    fi
    switch-session "${HOME}/${selected}"
elif [[ "$1" == "previous" ]]; then

    # Switch to previous session
    previous_session=$(head -n 2 "$TMUX_SESSION_HISTORY" | tail -n 1)
    if [[ -z $previous_session ]]; then
        exit 1
    fi
    tmux switch-client -t "$previous_session"

elif [[ -d "$1" ]]; then
    # Switch to session by name
    switch-session "$1"
fi
