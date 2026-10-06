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
  | (if $max_turns < 0 then . else .[-$max_turns:] end)
  | .[]
  | (.text | split("\n")) as $lines
  | (if ($lines | length) > $max_lines and $max_lines >= 0
     then ($lines[0:$max_lines] | join("\n"))
          + "\n  [2m[+" + (($lines | length) - $max_lines | tostring) + " more lines][0m"
     else .text end) as $body
  # $style "markdown" renders turn headers as level-1 headings so the pager can
  # treat the conversation as the markdown it mostly is. Claude writes only ##
  # and ###, so # stays unambiguous. "ansi" keeps the coloured form for fzf.
  | (if $style == "markdown"
     then (if .role == "user" then "# ❯ you" else "# ✻ claude" end)
     else (if .role == "user"
           then "[1;36m❯ you[0m"
           else "[1;35m✻ claude[0m" end) end)
    + "\n" + $body + "\n"
