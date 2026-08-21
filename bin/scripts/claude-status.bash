#!/usr/bin/env bash
# Outputs "● N" when N live Claude agents are waiting for input or blocked on a
# permission prompt. Used as a tmux status-right segment via #(claude-status.bash).

source "$(command -v claude-agents-common.bash)"

count=0
while IFS=$'\t' read -r pane session window status cwd; do
    if [[ "$status" == "waiting" || "$status" == "permission" ]]; then
        ((count++)) || true
    fi
done < <(claude_agents_each_live)

[[ $count -gt 0 ]] && echo "● $count"
exit 0
