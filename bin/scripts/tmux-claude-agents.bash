#!/usr/bin/env bash
# fzf popup picker for navigating between running Claude Code agents, with a
# preview of each agent's conversation. Bound to <prefix> a in tmux.conf.

# shellcheck source=SCRIPTDIR/claude-agents-common.bash
source "$(command -v claude-agents-common.bash)"

# Human-readable age of an ISO-8601 UTC timestamp, e.g. 2m, 1h, 3d.
_idle() {
    local ts="$1" started now delta
    [[ -z "$ts" ]] && { printf '?'; return; }
    started=$(TZ=UTC date -j -f '%Y-%m-%dT%H:%M:%SZ' "$ts" +%s 2>/dev/null) || { printf '?'; return; }
    now=$(date +%s)
    delta=$(( now - started ))
    (( delta < 0 )) && delta=0
    if   (( delta < 60 ));    then printf '%ds' "$delta"
    elif (( delta < 3600 ));  then printf '%dm' $(( delta / 60 ))
    elif (( delta < 86400 )); then printf '%dh' $(( delta / 3600 ))
    else                           printf '%dd' $(( delta / 86400 ))
    fi
}

reset=$'\033[0m'

# Each line is "<visible display>\t<session>\t<pane>\t<transcript>"; fzf shows
# only the first tab-delimited field and returns the whole line, so the values
# used for navigation and the conversation preview stay hidden but recoverable.
entries=()
while IFS=$'\037' read -r pane session status cwd transcript updated_at; do
    # Colours render because fzf runs with --ansi. Green: busy, yellow: done and
    # waiting on you, red: blocked on a permission prompt.
    case "$status" in
        waiting)    icon=$'\033[1;33m'"⏸""$reset" ;;
        running)    icon=$'\033[1;32m'"▶""$reset" ;;
        permission) icon=$'\033[1;31m'"⚠""$reset" ;;
        *)          icon=$'\033[2m'"?""$reset" ;;
    esac

    idle=$(_idle "$updated_at")
    branch=$(claude_agents_branch_for "$transcript")

    # The ~ is written inside double quotes so it is not expanded back to $HOME.
    short_cwd="$cwd"
    if [[ "$short_cwd" == "$HOME" || "$short_cwd" == "$HOME"/* ]]; then
        short_cwd="~${short_cwd#"$HOME"}"
    fi

    display=$(printf '%s  %-10s  %-4s  %-28s  %s' "$icon" "$status" "$idle" "$short_cwd" "${branch:--}")
    entries+=("$(printf '%s\t%s\t%s\t%s' "$display" "$session" "$pane" "$transcript")")
done < <(claude_agents_each_live)

if [[ ${#entries[@]} -eq 0 ]]; then
    tmux display-message "No Claude agents running"
    exit 0
fi

selected=$(printf '%s\n' "${entries[@]}" | fzf --tmux 90%,80% \
    --header="Claude Agents" --no-sort --ansi \
    --delimiter='\t' --with-nth=1 \
    --preview='claude-agent-preview.bash {4}' \
    --preview-window='right:60%:wrap')
[[ -z "$selected" ]] && exit 0

IFS=$'\t' read -r _ target_session target_pane _ <<< "$selected"
[[ -z "$target_pane" ]] && exit 0

tmux switch-client -t "$target_session" 2>/dev/null
tmux select-window -t "$target_pane" 2>/dev/null
tmux select-pane -t "$target_pane" 2>/dev/null
