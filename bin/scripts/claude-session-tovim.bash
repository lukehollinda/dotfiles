#!/usr/bin/env bash
# Open the Claude Code session running in a tmux pane in the nvim pager.
# Bound to <prefix> C in tmux.conf.
#   $1 = pane id to read the session from; defaults to the active pane.
set -uo pipefail

# shellcheck source=SCRIPTDIR/claude-agents-common.bash
source "$(command -v claude-agents-common.bash)"

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

exec claude-transcript-tovim.bash "$transcript"
