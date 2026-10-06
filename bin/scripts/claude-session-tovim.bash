#!/usr/bin/env bash
# Open the Claude Code session running in a tmux pane in the nvim pager, so the
# conversation can be navigated, searched and copied with normal vim motions.
# Bound to <prefix> C in tmux.conf.
#   $1 = pane id to read the session from; defaults to the active pane.
set -uo pipefail

# shellcheck source=SCRIPTDIR/claude-agents-common.bash
source "$(command -v claude-agents-common.bash)"

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

pane="${1:-$(tmux display-message -p '#{pane_id}')}"

found=0
transcript=""
while IFS=$'\037' read -r p _session _status _cwd t _updated; do
    if [[ "$p" == "$pane" ]]; then
        found=1
        transcript="$t"
        break
    fi
done < <(claude_agents_each_live)

if (( ! found )); then
    echo "No Claude session found in pane $pane." >&2
    exit 1
fi
# A session is registered before its transcript exists, so these differ.
if [[ -z "$transcript" || ! -f "$transcript" ]]; then
    echo "Claude session in pane $pane has no transcript yet." >&2
    exit 1
fi

# Negative limits mean no truncation: unlike the fzf preview this renders the
# whole conversation, and the pager needs every turn to be navigable.
{
    title=$(grep -F '"type":"ai-title"' "$transcript" 2>/dev/null | tail -n 1 \
        | jq -r '.aiTitle // empty' 2>/dev/null || true)
    [[ -n "$title" ]] && printf '\033[1m%s\033[0m\n\n' "$title"

    jq -rs --argjson max_turns -1 --arg style markdown --argjson max_lines -1 \
        -f "$script_dir/claude-transcript.jq" "$transcript" 2>/dev/null
} | nvim-pager -R "+lua require('pager').render_session()"
