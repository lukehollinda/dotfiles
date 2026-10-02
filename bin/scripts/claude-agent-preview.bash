#!/usr/bin/env bash
# Render a readable preview of a Claude conversation transcript for the fzf
# preview pane in tmux-claude-agents.bash.
#   $1 = path to the session's JSONL transcript
set -uo pipefail

TF="${1:-}"
if [[ -z "$TF" || ! -f "$TF" ]]; then
    echo "No conversation yet."
    exit 0
fi

# Conversation title, if Claude has generated one.
title=$(grep -F '"type":"ai-title"' "$TF" 2>/dev/null | tail -n 1 | jq -r '.aiTitle // empty' 2>/dev/null || true)
[[ -n "$title" ]] && printf '\033[1m%s\033[0m\n\n' "$title"

# Only the tail is parsed, for responsiveness on long transcripts (each JSONL
# line is self-contained, so tail-then-parse is safe). The turn-rendering
# filter is shared with the full-session view; the limits passed here keep the
# preview small enough that no single turn dominates the fzf pane.
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

tail -n 400 "$TF" | jq -rs --argjson max_turns 8 --argjson max_lines 12 \
    -f "$script_dir/claude-transcript.jq" 2>/dev/null
