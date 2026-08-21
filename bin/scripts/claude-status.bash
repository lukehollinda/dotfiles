#!/usr/bin/env bash
# Outputs "● N" when N live Claude agents are waiting for input or blocked on a
# permission prompt. Used as a tmux status-right segment via #(claude-status.bash).
#
# tmux runs this on every status-interval tick, so it also serves as the timer
# that reconciles window names with the running claude processes.

source "$(command -v claude-agents-common.bash)"

claude_agents_reconcile_window_names

count=0
while IFS=$'\t' read -r pane session window status cwd transcript; do
    if [[ "$status" == "waiting" || "$status" == "permission" ]]; then
        ((count++)) || true
    fi
done < <(claude_agents_each_live)

[[ $count -gt 0 ]] && echo "● $count"
exit 0
