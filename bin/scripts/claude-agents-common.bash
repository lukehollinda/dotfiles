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

# Print the git branch a session is on, from the transcript. Only the tail is
# scanned (gitBranch is recorded on nearly every line), so it stays cheap.
claude_agents_branch_for() {
    local transcript="$1"
    [[ -n "$transcript" && -f "$transcript" ]] || return 0
    tail -n 100 "$transcript" 2>/dev/null \
        | jq -r 'select(.gitBranch != null and .gitBranch != "") | .gitBranch' 2>/dev/null \
        | tail -n 1
}

# Emit one record per live agent, fields separated by US (0x1f):
#   pane<US>session<US>status<US>cwd<US>transcript<US>updated_at
# US is used rather than tab because `read` collapses runs of whitespace
# delimiters, so an empty field (e.g. a missing transcript) between two tabs
# would be swallowed and shift every later field. A non-whitespace delimiter
# keeps empty fields in place. Consumers split with IFS=$'\037'.
# State files whose pane no longer exists (dead pane, or legacy files with no
# recorded pane) are deleted as a side effect.
claude_agents_each_live() {
    [[ -d "$CLAUDE_AGENTS_DIR" ]] || return 0

    local live us
    live=$(claude_agents_live_panes)
    us=$'\037'

    # Note: avoid a variable literally named "status"; it is read-only in zsh,
    # and this file is a sourced library.
    local f session_id record pane session agent_status cwd transcript_path transcript updated_at
    for f in "$CLAUDE_AGENTS_DIR"/*.json; do
        [[ -f "$f" ]] || continue

        record=$(jq -r '[(.tmux_pane//""), (.tmux_session//""), (.status//""), (.cwd//""), (.transcript_path//""), (.updated_at//"")] | join("")' "$f" 2>/dev/null) || continue
        IFS="$us" read -r pane session agent_status cwd transcript_path updated_at <<<"$record"

        if [[ -z "$pane" ]] || ! grep -qxF "$pane" <<<"$live"; then
            rm -f "$f"
            continue
        fi

        session_id=$(basename "$f" .json)
        transcript=$(claude_agents_transcript_for "$session_id" "$transcript_path")

        printf '%s%s%s%s%s%s%s%s%s%s%s\n' \
            "$pane" "$us" "$session" "$us" "$agent_status" "$us" "$cwd" "$us" "$transcript" "$us" "$updated_at"
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
