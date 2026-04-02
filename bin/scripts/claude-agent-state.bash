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

_notify_user() {
    osascript -e "display notification \"$1\" with title \"Claude\""
}

# Send notification only when the user is unlikely to be watching the Claude window:
#   - Kitty is not the focused app, OR
#   - Kitty is focused but the Claude session's window is not currently active
_notify_if_unfocused() {
    local msg="$1" session="$2" window="$3"

    local frontmost
    frontmost=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || true)

    if [[ "$frontmost" != "kitty" ]]; then
        _notify_user "$msg"
        return
    fi

    # Kitty is focused — check if the session exists and the claude window is the active one
    local active_window attached_count
    active_window=$(tmux display-message -t "$session" -p '#{window_index}' 2>/dev/null || true)
    attached_count=$(tmux list-clients -F '#{client_session}' 2>/dev/null | grep -c "^${session}$" || echo 0)

    if [[ "$attached_count" -eq 0 || "$active_window" != "$window" ]]; then
        _notify_user "$msg"
    fi
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
        tmux_session=$(jq -r '.tmux_session // empty' "$STATE_FILE" 2>/dev/null)
        tmux_window=$(jq -r '.tmux_window // empty' "$STATE_FILE" 2>/dev/null)
        _notify_if_unfocused "${tmux_session}: Ready" "$tmux_session" "$tmux_window"
        ;;
    PermissionRequest)
        _update_status "permission"
        tmux_session=$(jq -r '.tmux_session // empty' "$STATE_FILE" 2>/dev/null)
        tmux_window=$(jq -r '.tmux_window // empty' "$STATE_FILE" 2>/dev/null)
        _notify_if_unfocused "${tmux_session}: Requesting Permission" "$tmux_session" "$tmux_window"
        ;;
    SessionEnd)
        rm -f "$STATE_FILE"
        ;;
esac

exit 0
