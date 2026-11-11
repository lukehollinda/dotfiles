-- Every key binding, except the resize mode's own keys in resize.lua. The
-- custom actions they name are defined in the files required here.
require("sessions")
require("agents")
require("resize")

rex.bind("ctrl+a>ctrl+a", "pane.send_key", { key = "ctrl+a" })

-- Panes and tabs
rex.bind("ctrl+a>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+a>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+a>k", "pane.focus", { direction = "up" })
rex.bind("ctrl+a>l", "pane.focus", { direction = "right" })
rex.bind("ctrl+a>v", "pane.split", { direction = "right" })
rex.bind("ctrl+a>s", "pane.split", { direction = "down" })
rex.bind("ctrl+a>c", "client.tab.new")
rex.bind("ctrl+a>=", "pane.balance")
rex.bind("ctrl+a>z", "pane.zoom")
for key, direction in pairs{ h = "left", j = "down", k = "up", l = "right" } do
  rex.bind("ctrl+a>shift+" .. key, "resize_pane_and_repeat", { direction = direction })
end

-- Sessions. Every key that can leave a session records it for prefix -.
rex.bind("ctrl+a>o", "open_project")
rex.bind("ctrl+a>-", "previous_session")
rex.bind("ctrl+a>w", "switch_tracked", { action = "session.switch" })
rex.bind("cmd+k", "switch_tracked", { action = "session.switch" })
rex.bind("cmd+p", "switch_tracked", { action = "pane.go_to" })
for index = 1, 9 do
  rex.bind("cmd+[Digit" .. index .. "]", "switch_tracked",
    { action = "client.tab.goto", args = { index = index } })
end

-- Agents
rex.bind("ctrl+a>shift+n", "new_agent")
rex.bind("ctrl+a>e", "open_nvim")
rex.bind("ctrl+a>shift+a", "open_transcript")
rex.bind("ctrl+a>shift+x", "close_work")
