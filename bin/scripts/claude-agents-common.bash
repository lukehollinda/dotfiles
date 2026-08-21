#!/usr/bin/env bash
# Shared helpers for Claude Code agent state tracking.
#
# State files live at ~/.tmux/claude-agents/{session_id}.json, one per Claude
# instance, and record the tmux pane hosting that instance. A pane id is
# globally unique within a tmux server, so an agent is "live" iff its pane still
# exists. This is what lets multiple Claude instances share one tmux session and
# lets readers reap state left behind when a pane, the tmux server, or the
# machine goes away without SessionEnd ever firing.

CLAUDE_AGENTS_DIR="${CLAUDE_AGENTS_DIR:-$HOME/.tmux/claude-agents}"

# Print every currently-live tmux pane id, one per line.
claude_agents_live_panes() {
    tmux list-panes -a -F '#{pane_id}' 2>/dev/null
}

# Emit one tab-separated record per live agent:
#   pane<TAB>session<TAB>window<TAB>status<TAB>cwd
# State files whose pane no longer exists (dead pane, or legacy files with no
# recorded pane) are deleted as a side effect.
claude_agents_each_live() {
    [[ -d "$CLAUDE_AGENTS_DIR" ]] || return 0

    local live
    live=$(claude_agents_live_panes)

    local f record pane session window status cwd
    for f in "$CLAUDE_AGENTS_DIR"/*.json; do
        [[ -f "$f" ]] || continue

        record=$(jq -r '[.tmux_pane, .tmux_session, .tmux_window, .status, .cwd] | @tsv' "$f" 2>/dev/null) || continue
        IFS=$'\t' read -r pane session window status cwd <<<"$record"

        if [[ -z "$pane" ]] || ! grep -qxF "$pane" <<<"$live"; then
            rm -f "$f"
            continue
        fi

        printf '%s\t%s\t%s\t%s\t%s\n' "$pane" "$session" "$window" "$status" "$cwd"
    done
}
