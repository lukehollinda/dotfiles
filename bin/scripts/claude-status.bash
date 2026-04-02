#!/usr/bin/env bash
# Outputs "● N" when N Claude agents are waiting for input or blocked on a permission prompt.
# Used as a tmux status-right segment via #(claude-status.bash).

STATE_DIR="$HOME/.tmux/claude-agents"
[[ -d "$STATE_DIR" ]] || exit 0

count=0
for f in "$STATE_DIR"/*.json; do
    [[ -f "$f" ]] || continue
    status=$(jq -r '.status // empty' "$f" 2>/dev/null)
    if [[ "$status" == "waiting" || "$status" == "permission" ]]; then
        ((count++)) || true
    fi
done

[[ $count -gt 0 ]] && echo "● $count"
exit 0
