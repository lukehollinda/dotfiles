#!/usr/bin/env bash
# Hook handler for Claude Code agent state tracking.
# Called with the event name as $1; reads hook JSON payload from stdin.
# State files: ~/.tmux/claude-agents/{session_id}.json

set -euo pipefail

EVENT="${1:-}"
STATE_DIR="$HOME/.tmux/claude-agents"
mkdir -p "$STATE_DIR"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

[[ -z "$SESSION_ID" ]] && exit 0

STATE_FILE="$STATE_DIR/${SESSION_ID}.json"

_update_status() {
    local status="$1"
    [[ -f "$STATE_FILE" ]] || return 0
    local tmp
    tmp=$(mktemp)
    jq --arg s "$status" --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '.status = $s | .updated_at = $t' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

case "$EVENT" in
    SessionStart)
        TMUX_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null || true)
        TMUX_WINDOW=$(tmux display-message -p '#{window_index}' 2>/dev/null || true)

        if [[ -n "$TMUX_SESSION" && -n "$TMUX_WINDOW" ]]; then
            tmux rename-window -t "${TMUX_SESSION}:${TMUX_WINDOW}" claude 2>/dev/null || true
        fi

        jq -n \
            --arg status "waiting" \
            --arg tmux_session "$TMUX_SESSION" \
            --arg tmux_window "$TMUX_WINDOW" \
            --arg cwd "$CWD" \
            --arg updated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            '{status: $status, tmux_session: $tmux_session, tmux_window: $tmux_window, cwd: $cwd, updated_at: $updated_at}' \
            > "$STATE_FILE"
        ;;
    UserPromptSubmit)
        _update_status "running"
        ;;
    Stop)
        _update_status "waiting"
        ;;
    PermissionRequest)
        _update_status "permission"
        ;;
    SessionEnd)
        rm -f "$STATE_FILE"
        ;;
esac

exit 0
