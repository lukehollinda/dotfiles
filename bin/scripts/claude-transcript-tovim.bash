#!/usr/bin/env bash
# Open a Claude Code transcript in the nvim pager, so the conversation can be
# navigated, searched and copied with normal vim motions.
#   $1 = path to the session's JSONL transcript
set -uo pipefail

transcript="$1"
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# Negative limits mean no truncation: unlike the fzf preview this renders the
# whole conversation, and the pager needs every turn to be navigable.
{
    # A heading, not ANSI bold: nothing consumes escape sequences in a markdown
    # buffer, so they would sit in the text and come out in yanks.
    title=$(grep -F '"type":"ai-title"' "$transcript" 2>/dev/null | tail -n 1 \
        | jq -r '.aiTitle // empty' 2>/dev/null || true)
    [[ -n "$title" ]] && printf '# %s\n\n' "$title"

    jq -rs --argjson max_turns -1 --arg style markdown --argjson max_lines -1 \
        -f "$script_dir/claude-transcript.jq" "$transcript" 2>/dev/null
} | nvim-pager -R "+lua require('pager').render_session()"
