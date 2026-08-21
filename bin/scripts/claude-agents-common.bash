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

# Resolve a session's transcript. Prefers the path recorded by the hook, and
# falls back to the projects dir, where the transcript is named after the
# session id, which is also the state file's name.
claude_agents_transcript_for() {
    local session_id="$1" recorded="$2"
    if [[ -n "$recorded" && -f "$recorded" ]]; then
        printf '%s' "$recorded"
        return
    fi
    local hit
    hit=$(ls -t "$HOME"/.claude/projects/*/"$session_id".jsonl 2>/dev/null | head -n 1)
    printf '%s' "$hit"
}

# Emit one tab-separated record per live agent:
#   pane<TAB>session<TAB>window<TAB>status<TAB>cwd<TAB>transcript
# State files whose pane no longer exists (dead pane, or legacy files with no
# recorded pane) are deleted as a side effect.
claude_agents_each_live() {
    [[ -d "$CLAUDE_AGENTS_DIR" ]] || return 0

    local live
    live=$(claude_agents_live_panes)

    # Note: avoid a variable literally named "status"; it is read-only in zsh,
    # and this file is a sourced library.
    local f session_id record pane session window agent_status cwd transcript_path transcript
    for f in "$CLAUDE_AGENTS_DIR"/*.json; do
        [[ -f "$f" ]] || continue

        record=$(jq -r '[.tmux_pane, .tmux_session, .tmux_window, .status, .cwd, .transcript_path] | @tsv' "$f" 2>/dev/null) || continue
        IFS=$'\t' read -r pane session window agent_status cwd transcript_path <<<"$record"

        if [[ -z "$pane" ]] || ! grep -qxF "$pane" <<<"$live"; then
            rm -f "$f"
            continue
        fi

        session_id=$(basename "$f" .json)
        transcript=$(claude_agents_transcript_for "$session_id" "$transcript_path")

        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$pane" "$session" "$window" "$agent_status" "$cwd" "$transcript"
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
