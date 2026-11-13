#!/usr/bin/env bash
# Start Claude in a new worktree of the repo a directory belongs to. Claude Code
# creates the worktree under <repo>/.claude/worktrees/ from the base the repo's
# worktree.baseRef setting selects (origin's default branch unless the repo sets
# head), and refuses to unless the repo is trusted. The agent names its Rex tab
# for the session's topic, and renames the worktree's placeholder branch when it
# has a change to commit.
#
# The agent starts in Unsupervised mode, so it can commit on its own branch in
# its own worktree. /unsupervised is its first message, which loads the rules
# and sets the status line as it does when typed.
#   $1 = a directory in the project
#   $2 = the agent's first user message (optional)

common=$(git -C "$1" rev-parse --path-format=absolute --git-common-dir) || exit 1
repo=$(dirname "$common")
git -C "$repo" fetch --quiet origin

read -r -d '' prompt <<'EOF'
This session runs in a git worktree that Claude Code created for it, on a
placeholder branch named worktree-<name>, in its own Rex tab. The tab and the
branch are named separately.

Tab: after the first instruction you receive, name the tab with a short
lowercase hyphenated label for what the session is about, whether or not there
is a concrete task. Skip this if the tab already has a name other than "agent".
Update the label if the focus of the session shifts. The tab keeps this topic
name and does not follow the branch name. A bare /unsupervised is not an
instruction: until one arrives the tab stays "agent".
rex window inspect -s "$REX_SESSION" "$(rex block inspect "$REX_BLOCK" --json | jq -r .block.window_id)" --json | jq -r .label
rex window rename -s "$REX_SESSION" "$(rex block inspect "$REX_BLOCK" --json | jq -r .block.window_id)" <label>

Branch: renaming the placeholder branch is approved. Rename it to
lh-<description> with `git branch -m` only when there is a concrete change to
commit.

The launcher that started this session runs /unsupervised as its first message,
on the user's standing instruction. Any text after the command in that message
is the user's task: after the confirmation line, carry it out.
EOF

# exec keeps claude the pane's foreground process, which rex-close.bash reads.
cd "$repo" && exec claude --worktree --append-system-prompt "$prompt" -- "/unsupervised${2:+ $2}"
