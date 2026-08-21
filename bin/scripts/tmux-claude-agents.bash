#!/usr/bin/env bash
# fzf popup picker for navigating between running Claude Code agents.
# Bound to <prefix> C-l in tmux.conf.

source "$(command -v claude-agents-common.bash)"

# Each line is "<visible display>\t<session>\t<pane>"; fzf shows only the first
# tab-delimited field and returns the whole line, so the session and pane id we
# navigate with stay hidden but recoverable.
entries=()
while IFS=$'\t' read -r pane session window status cwd; do
    case "$status" in
        waiting)    icon="⏸" ;;
        running)    icon="▶" ;;
        permission) icon="⚠" ;;
        *)          icon="?" ;;
    esac

    display=$(printf '%s  %-10s  %-5s  %s:%s  %s' "$icon" "$status" "$pane" "$session" "$window" "$cwd")
    entries+=("$(printf '%s\t%s\t%s' "$display" "$session" "$pane")")
done < <(claude_agents_each_live)

if [[ ${#entries[@]} -eq 0 ]]; then
    tmux display-message "No Claude agents running"
    exit 0
fi

selected=$(printf '%s\n' "${entries[@]}" | fzf --tmux 80%,60% --header="Claude Agents" --no-sort --ansi --delimiter='\t' --with-nth=1)
[[ -z "$selected" ]] && exit 0

target_session=$(printf '%s' "$selected" | awk -F'\t' '{print $2}')
target_pane=$(printf '%s' "$selected" | awk -F'\t' '{print $3}')
[[ -z "$target_pane" ]] && exit 0

tmux switch-client -t "$target_session" 2>/dev/null
tmux select-window -t "$target_pane" 2>/dev/null
tmux select-pane -t "$target_pane" 2>/dev/null
