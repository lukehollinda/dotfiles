#!/usr/bin/env bash
# Close what a pane belongs to: in an agent's tab (a worktree under
# .claude/worktrees/), remove the worktree and close the tab; anywhere else,
# close the session.
#
# Killing nvim leaves its LSP servers running as orphans, so each nvim is asked
# to quit first. Nothing closes while an nvim holds unsaved buffers, the worktree
# has changes or commits that are not pushed, or, for a session, any pane runs
# Claude.
#   $1 = session, $2 = the pane to close from

session="$1"
block="$2"

refuse() {
    echo "$1"
    read -r -s -n 1 -p "Press any key to close."
    exit 1
}

# $1 = block, $2 = field of its foreground process, such as name or cwd
foreground() {
    rex block call -s "$session" -b "$1" process | jq -r --arg field "$2" '.foreground[$field] // empty'
}

blocks_json=$(rex block ls -s "$session" --json)
cwd=$(foreground "$block" cwd)
worktree=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
[[ "$worktree" == */.claude/worktrees/* ]] || worktree=""

if [[ -n "$worktree" ]]; then
    window=$(jq -r --arg b "$block" '.blocks[] | select(.block_id == $b) | .window_id' <<<"$blocks_json")
    blocks=$(jq -r --arg w "$window" '.blocks[] | select(.window_id == $w) | .block_id' <<<"$blocks_json")

    [[ -n "$(git -C "$worktree" status --porcelain)" ]] && refuse "Uncommitted changes in $worktree."
    base=$(git -C "$worktree" rev-parse --abbrev-ref '@{u}' 2>/dev/null) \
        || base=$(git -C "$worktree" symbolic-ref --short refs/remotes/origin/HEAD)
    unpushed=$(git -C "$worktree" rev-list --count "$base..HEAD")
    (( unpushed > 0 )) && refuse "$unpushed commits in $worktree are not on $base."
else
    blocks=$(jq -r '.blocks[].block_id' <<<"$blocks_json")
    for b in $blocks; do
        [[ "$(foreground "$b" name)" == "claude" ]] && refuse "Claude is running in this session; quit it first."
    done
fi

nvims=()
for b in $blocks; do
    [[ "$(foreground "$b" name)" == "nvim" ]] && nvims+=("$b")
done

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

# Have each nvim write out its count of modified buffers, and abort if any has one.
for b in "${nvims[@]}"; do
    # Clear the previous pane's count so it cannot be read as this pane's
    : > "$tmpfile"
    # Escape first so the command line is reached from normal mode.
    rex send-key -s "$session" -b "$b" esc
    rex send -s "$session" -b "$b" ":call writefile([len(filter(getbufinfo(), 'v:val.changed'))], '$tmpfile')"
    rex send-key -s "$session" -b "$b" enter
    sleep 0.2

    unsaved=$(cat "$tmpfile")
    (( ${unsaved:-0} > 0 )) && refuse "nvim has unsaved changes."
done

for b in "${nvims[@]}"; do
    rex send -s "$session" -b "$b" ":qa"
    rex send-key -s "$session" -b "$b" enter
done

# This script runs in a floating pane inside what it closes, so closing is last.
if [[ -n "$worktree" ]]; then
    # Claude Code locks the worktree while it runs; the checks above stand in for the lock.
    git -C "$worktree" worktree unlock "$worktree"
    git -C "$worktree" worktree remove "$worktree"
    rex window close -s "$session" "$window"
else
    rex kill "$session"
fi
