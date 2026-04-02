#!/usr/bin/env bash
# fzf popup picker for navigating between running Claude Code agents.
# Bound to <prefix> C-l in tmux.conf.

STATE_DIR="$HOME/.tmux/claude-agents"

entries=()
session_window=()

for f in "$STATE_DIR"/*.json; do
    [[ -f "$f" ]] || continue
    session=$(jq -r '.tmux_session // empty' "$f" 2>/dev/null)
    window=$(jq -r '.tmux_window // empty' "$f" 2>/dev/null)
    status=$(jq -r '.status // empty' "$f" 2>/dev/null)
    cwd=$(jq -r '.cwd // empty' "$f" 2>/dev/null)

    [[ -z "$session" ]] && continue

    case "$status" in
        waiting)    icon="⏸" ;;
        running)    icon="▶" ;;
        permission) icon="⚠" ;;
        *)          icon="?" ;;
    esac

    entries+=("$icon  $(printf '%-10s' "$status")  ${session}:${window}  ${cwd}")
    session_window+=("${session}:${window}")
done

if [[ ${#entries[@]} -eq 0 ]]; then
    tmux display-message "No Claude agents running"
    exit 0
fi

selected=$(printf '%s\n' "${entries[@]}" | fzf --tmux 80%,60% --header="Claude Agents" --no-sort --ansi)
[[ -z "$selected" ]] && exit 0

# Extract session:window from column 3 of the selected line
target=$(echo "$selected" | awk '{print $3}')
tmux switch-client -t "$target" 2>/dev/null || tmux display-message "Session not found: $target"
