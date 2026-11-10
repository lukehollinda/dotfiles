#!/usr/bin/env bash
# Pick a git repo with fzf and switch to its Rex session, creating the session if
# needed. A new session opens a "main" tab with nvim beside a shell, except
# "scratch", which gets a bare shell.
#   $1 = the client to switch, as passed by the open_project action
#   $2 = the session history file, most recent session first

PROJECT_DIRECTORIES=(
    "$HOME"
    "$HOME/work"
    "$HOME/person"
    "$HOME/person/dev"
    "$HOME/upstream"
)

client_args=()
[[ -n "${1:-}" ]] && client_args=(-C "$1")

# Each session label's place in the history; open sessions missing from it rank
# after those in it, and repos without a session after both.
ranks=$(rex ls --json | jq -c --rawfile history <(cat "${2:-}" 2>/dev/null) '
    ($history | split("\n")) as $ids
    | [.sessions[] | .session_id as $id | {key: .label, value: ($ids | index($id) // 1e6)}]
    | from_entries')

# --tiebreak=index keeps that order among equally good matches.
selected=$(find "${PROJECT_DIRECTORIES[@]}" -mindepth 2 -maxdepth 2 -type d -name ".git" 2>/dev/null \
    | sed -e 's|/\.git$||' -e "s|^$HOME/||" \
    | jq -R -n -r --argjson ranks "$ranks" '[inputs] | sort_by($ranks[split("/") | last] // 2e6) | .[]' \
    | fzf --tiebreak=index)
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
