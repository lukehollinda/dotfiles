#!/usr/bin/env bash
# Render a readable preview of a Claude conversation transcript for the fzf
# preview pane in tmux-claude-agents.bash.
#   $1 = path to the session's JSONL transcript
set -uo pipefail

TF="${1:-}"
if [[ -z "$TF" || ! -f "$TF" ]]; then
    echo "No conversation yet."
    exit 0
fi

# Conversation title, if Claude has generated one.
title=$(grep -F '"type":"ai-title"' "$TF" 2>/dev/null | tail -n 1 | jq -r '.aiTitle // empty' 2>/dev/null || true)
[[ -n "$title" ]] && printf '\033[1m%s\033[0m\n\n' "$title"

# Only the tail is parsed, for responsiveness on long transcripts (each JSONL
# line is self-contained, so tail-then-parse is safe). Assistant content is
# stored one block per line, so consecutive same-role messages are merged to
# give each turn a single header; only the last few turns are shown, and long
# messages are capped so no single turn dominates the pane.
tail -n 400 "$TF" | jq -rs '
  [ .[]
    | select((.isMeta // false) == false)
    | select((.isSidechain // false) == false)
    | select(.type == "user" or .type == "assistant")
    | .message as $m
    | if $m.role == "user" then
        { role: "user",
          text: (if ($m.content | type) == "string" then $m.content else "" end) }
      else
        { role: "assistant",
          text: (($m.content // [])
                 | map(if .type == "text" then .text
                       elif .type == "tool_use" then "  ⚙ " + .name
                       else empty end)
                 | join("\n")) }
      end
    | select((.text | length) > 0)
    | select(.role == "assistant"
             or (.text | test("^<(command-|local-command|system-reminder|bash-|user-|new-session)") | not))
  ]
  | reduce .[] as $x (
      [];
      if (length > 0 and .[-1].role == $x.role)
      then .[0:-1] + [{ role: $x.role, text: (.[-1].text + "\n" + $x.text) }]
      else . + [$x] end)
  | .[-8:]
  | .[]
  | (.text | split("\n")) as $lines
  | (if ($lines | length) > 12
     then ($lines[0:12] | join("\n"))
          + "\n  [2m[+" + (($lines | length) - 12 | tostring) + " more lines][0m"
     else .text end) as $body
  | (if .role == "user"
     then "[1;36m❯ you[0m"
     else "[1;35m✻ claude[0m" end)
    + "\n" + $body + "\n"
' 2>/dev/null
