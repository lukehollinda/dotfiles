#!/usr/bin/env bash
# Pick a git repo with fzf and switch to its Rex session, creating the session if
# needed. A new session opens a "main" tab with nvim beside a shell, except
# "scratch", which gets a bare shell.
#   $1 = the client to switch, as passed by the open_project action

PROJECT_DIRECTORIES=(
    "$HOME"
    "$HOME/work"
    "$HOME/person"
    "$HOME/person/dev"
    "$HOME/upstream"
)

client_args=()
[[ -n "${1:-}" ]] && client_args=(-C "$1")

selected=$(find "${PROJECT_DIRECTORIES[@]}" -mindepth 2 -maxdepth 2 -type d -name ".git" 2>/dev/null \
    | sed -e 's|/\.git$||' -e "s|^$HOME/||" \
    | fzf)
[[ -z "$selected" ]] && exit 0

dir="$HOME/$selected"
name=$(basename "$dir")

session=$(rex ls --json | jq -r --arg name "$name" \
    'first(.sessions[] | select(.label == $name) | .session_id) // empty')

if [[ -z "$session" ]]; then
    created=$(rex new "$name" -c "$dir" --window main --json) || exit 1
    session=$(jq -r '.session_id' <<<"$created")

    if [[ "$name" != "scratch" ]]; then
        editor=$(jq -r '.initial_windows[0].block_ids[0]' <<<"$created")
        rex split -s "$session" -b "$editor" --split=right --ratio 35 --focus=false -c "$dir" >/dev/null
        # Typed into a shell, so quitting nvim leaves the shell behind.
        rex send -s "$session" -b "$editor" 'nvim .'
        rex send-key -s "$session" -b "$editor" enter
    fi
fi

rex "${client_args[@]}" do session.select session_id="$session"
