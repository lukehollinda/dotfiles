#!/usr/bin/env bash
# Shared helpers for Claude Code agent state tracking.
#
# State files live at ~/.tmux/claude-agents/{session_id}.json, one per Claude
# instance, and record the tmux pane hosting that instance. A pane id is
# globally unique within a tmux server, so an agent is "live" if its pane still
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

# Keep tmux window names matching reality: a window is named "claude" if it
# currently hosts a claude pane; otherwise automatic-rename is restored so tmux
# tracks the running command again. Idempotent, so it is safe to run on a timer.
# This is the sole owner of the "claude" window name, which is why nothing else
# renames windows.
claude_agents_reconcile_window_names() {
    local claude_windows
    claude_windows=$(tmux list-panes -a -F '#{window_id} #{pane_current_command}' 2>/dev/null \
        | awk '$2 == "claude" { print $1 }' | sort -u)

    local win name
    while IFS=$'\t' read -r win name; do
        [[ -z "$win" ]] && continue
        if grep -qxF "$win" <<<"$claude_windows"; then
            # rename-window also turns automatic-rename off, pinning the name.
            [[ "$name" == "claude" ]] || tmux rename-window -t "$win" claude 2>/dev/null
        elif [[ "$name" == "claude" ]]; then
            tmux set-window-option -t "$win" automatic-rename on 2>/dev/null
        fi
    done < <(tmux list-windows -a -F '#{window_id}'$'\t''#{window_name}' 2>/dev/null)
}
