alias g="git"
alias gs="git status"
alias ga='git add'
alias gaa="git add --all"
alias gco='git checkout'
alias gp='git pull'
alias gca='git commit --amend --verbose'
alias gr='git rebase'

# Because I forget the config option
alias gitupstream='git config --get remote.origin.url'

# Copy message from previous commit to clipboard
alias gmcp="git log -1 --pretty=%B | pbcopy"

# Log with files changed
alias glog='git log --name-only'

# Quick diffing
alias gdiff='git diff'
alias gdiffs='git diff --staged .'

# Switch git repo from ssh <-> https
alias git-ssh='git remote set-url origin "$(git remote get-url origin | sed -E '\''s,^https://([^/]*)/(.*)$,git@\1:\2,'\'')"'
alias git-https='git remote set-url origin "$(git remote get-url origin | sed -E '\''s,^git@([^:]*):/*(.*)$,https://\1/\2,'\'')"'

# Change cwd to top of git repo
alias cdg='cd "$(git rev-parse --show-toplevel || echo .)"'

# Git Checkout Master / Main
gcom() {
	local base
	base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
	if [[ -z "$base" ]]; then
		# Fall back to whichever of main/master exists locally
		if git show-ref --verify --quiet refs/heads/main; then
			base="main"
		else
			base="master"
		fi
	fi
	git checkout "$base" "$@"
}

# Git Rebase Master / Main
grim() {
	local base
	base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
	if [[ -z "$base" ]]; then
		# Fall back to whichever of main/master exists locally
		if git show-ref --verify --quiet refs/heads/main; then
			base="main"
		else
			base="master"
		fi
	fi
	git rebase -i "$base" "$@"
}

# Git Commit - Always verbose, add Jira ticket as trailer if found in branch name
gc() {
	local branch
	branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
		echo "Not in a git repository"
		return 1
	}
	local ticket
	ticket=$(echo "$branch" | grep -Eo -i '^[A-Za-z]+-[0-9]+')
	if [[ -z $ticket ]]; then
		git commit --verbose "$@"
	else
		git commit --trailer "Issue: $ticket" --trailer "Tracker: Jira" --verbose "$@"
	fi
}

# Create fixup commit, selecting parent via fzf. To be used with rebase.autoSquash = true
gfixup () {
	# fzf select branch and trim to SHA
	git commit --fixup $(git log --oneline | fzf --tmux | awk '{print $1}')
}

# fzf select and checkout recently visited branches - Adapted from https://gist.github.com/jordan-brough/48e2803c0ffa6dc2e0bd
grecent () {
	local branches=(
	  $(git reflog |
	    egrep -io "moving from ([^[:space:]]+)" |
	    awk '{ print $3 }' | # extract 3rd column
	    awk ' !x[$0]++' | # Removes duplicates.  See http://stackoverflow.com/questions/11532157
	    egrep -v '^[a-f0-9]{40}$' | # remove hash results
	    head -n 10
	  )
	)
	local result=$(printf '%s\n' "${branches[@]}" | fzf --tmux)
	if [[ -n $result ]]; then
		git switch $result
	fi
}

# Git checkout PR Branches
gcopr () {
	local selection=$(gh pr list | awk -F '\t' '{print $3}' | fzf --tmux)

	if [[ $selection ]]; then
		git checkout -b "$selection"
	fi
}
