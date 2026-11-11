#!/usr/bin/env bash
# Open the transcript of the Claude session in a Rex pane in the nvim pager.
#   $1 = the pane's block id

transcript=$(cat "$HOME/.local/state/rex/transcripts/$1" 2>/dev/null)

# A session is recorded before its transcript exists, so check the file too.
if [[ ! -f "$transcript" ]]; then
    echo "No Claude transcript for this pane yet."
    read -r -s -n 1 -p "Press any key to close."
    exit 1
fi

exec claude-transcript-tovim.bash "$transcript"
