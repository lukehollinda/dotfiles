#!/usr/bin/env bash

SESSION_PICKER_DIRECTORIES=(
  "$HOME/work/dev"
  "$HOME/work/upstream"
  "$HOME/person"
  "$HOME/person/dev"
  "$HOME/person/upstream"
)
select-project() {
    find "${SESSION_PICKER_DIRECTORIES[@]}" -mindepth 2 -maxdepth 2 -type d -name ".git" \
        | sed 's|/\.git$||' \
        | fzf
}

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(select-project)
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    echo "Please run from inside tmux"
    exit 0
    # tmux new-session -s "$selected_name" -c "$selected"
    # exit 0
fi

if ! tmux has-session -t="$selected_name" 2> /dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"  'nvim .'
fi

tmux switch-client -t "$selected_name"
