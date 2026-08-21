#!/usr/bin/env bash
# Hook handler for Claude Code agent state tracking.
# Called with the event name as $1; reads hook JSON payload from stdin.
# State files: ~/.tmux/claude-agents/{session_id}.json
#
# Each agent is identified by the tmux pane it runs in (tmux_pane), so multiple
# Claude instances can share one tmux session. Every event rewrites the full
# record, which self-heals a state file that a reader reaped after wrongly
# judging its pane dead.

set -euo pipefail

EVENT="${1:-}"
STATE_DIR="$HOME/.tmux/claude-agents"
mkdir -p "$STATE_DIR"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

[[ -z "$SESSION_ID" ]] && exit 0

STATE_FILE="$STATE_DIR/${SESSION_ID}.json"

# Populated by _write_state, reused by the notification helpers.
TMUX_SESSION=""
TMUX_WINDOW=""
TMUX_PANE_ID=""

_write_state() {
    local status="$1"
    TMUX_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null || true)
    TMUX_WINDOW=$(tmux display-message -p '#{window_index}' 2>/dev/null || true)
    TMUX_PANE_ID="${TMUX_PANE:-}"

    jq -n \
        --arg status "$status" \
        --arg tmux_session "$TMUX_SESSION" \
        --arg tmux_window "$TMUX_WINDOW" \
        --arg tmux_pane "$TMUX_PANE_ID" \
        --arg cwd "$CWD" \
        --arg updated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{status: $status, tmux_session: $tmux_session, tmux_window: $tmux_window, tmux_pane: $tmux_pane, cwd: $cwd, updated_at: $updated_at}' \
        > "$STATE_FILE"
}

_notify_user() {
    osascript -e "display notification \"$1\" with title \"Claude\""
}

# Notify unless the user is actively looking at this Claude pane: Kitty is
# frontmost AND this pane's session is attached AND its window and pane are the
# active ones. tmux resolves the flags for the calling (Claude) pane.
_notify_if_unfocused() {
    local msg="$1"

    local frontmost
    frontmost=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || true)
    if [[ "$frontmost" != "kitty" ]]; then
        _notify_user "$msg"
        return
    fi

    local flags attached wactive pactive
    flags=$(tmux display-message -p '#{session_attached}:#{window_active}:#{pane_active}' 2>/dev/null || true)
    IFS=: read -r attached wactive pactive <<<"$flags"

    if [[ "${attached:-0}" -ge 1 && "$wactive" == "1" && "$pactive" == "1" ]]; then
        return
    fi
    _notify_user "$msg"
}

case "$EVENT" in
    SessionStart)
        _write_state "waiting"
        if [[ -n "$TMUX_SESSION" && -n "$TMUX_WINDOW" ]]; then
            tmux rename-window -t "${TMUX_SESSION}:${TMUX_WINDOW}" claude 2>/dev/null || true
        fi
        ;;
    UserPromptSubmit)
        _write_state "running"
        ;;
    Stop)
        _write_state "waiting"
        _notify_if_unfocused "${TMUX_SESSION}: Ready"
        ;;
    PermissionRequest)
        _write_state "permission"
        _notify_if_unfocused "${TMUX_SESSION}: Requesting Permission"
        ;;
    SessionEnd)
        rm -f "$STATE_FILE"
        ;;
esac

exit 0
