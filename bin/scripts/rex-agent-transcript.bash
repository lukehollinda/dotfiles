#!/usr/bin/env bash
# Claude Code hook: record the transcript the Claude in each Rex pane writes, for
# rex-transcript-tovim.bash. Run on SessionStart, which also fires after /clear
# and /resume, and on SessionEnd. Reads the hook's JSON payload from stdin.
#   $1 = the hook event

[[ -n "${REX_BLOCK:-}" ]] || exit 0

dir="$HOME/.local/state/rex/transcripts"
record="$dir/$REX_BLOCK"

case "$1" in
    SessionStart)
        mkdir -p "$dir"
        jq -r '.transcript_path // empty' > "$record"
        ;;
    SessionEnd)
        rm -f "$record"
        ;;
esac
