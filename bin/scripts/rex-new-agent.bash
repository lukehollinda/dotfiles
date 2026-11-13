#!/usr/bin/env bash
# Start Claude in a new worktree of the repo a directory belongs to. Claude Code
# creates the worktree under <repo>/.claude/worktrees/ from the base the repo's
# worktree.baseRef setting selects (origin's default branch unless the repo sets
# head), and refuses to unless the repo is trusted. The agent renames the
# worktree's placeholder branch and its Rex tab once it knows the task.
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
placeholder branch named worktree-<name>. Renaming that branch is approved: once
you understand the task, rename it to lh-<description> with `git branch -m`,
then rename this Rex tab to match:
rex window rename -s "$REX_SESSION" "$(rex block inspect "$REX_BLOCK" --json | jq -r .block.window_id)" <branch>

The launcher that started this session runs /unsupervised as its first message,
on the user's standing instruction. Any text after the command in that message
is the user's task: after the confirmation line, carry it out.
EOF

# exec keeps claude the pane's foreground process, which rex-close.bash reads.
cd "$repo" && exec claude --worktree --append-system-prompt "$prompt" -- "/unsupervised${2:+ $2}"
