rex.bind("ctrl+a>ctrl+a", "pane.send_key", { key = "ctrl+a" })
rex.bind("ctrl+a>w", "session.switch")

rex.bind("ctrl+a>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+a>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+a>k", "pane.focus", { direction = "up" })
rex.bind("ctrl+a>l", "pane.focus", { direction = "right" })

rex.bind("ctrl+a>v", "pane.split", { direction = "right" })
rex.bind("ctrl+a>s", "pane.split", { direction = "down" })
rex.bind("ctrl+a>c", "client.tab.new")
rex.bind("ctrl+a>=", "pane.balance")

local scripts = os.getenv("HOME") .. "/dotfiles/bin/scripts/"

-- Runs an interactive script over the active tab; the pane closes when it exits.
local function float(argv)
  local _, err = rex.session.new_layer{
    bounds = { 0.1, 0.1, 0.8, 0.8 },
    focus = true,
    layout = rex.layout.block{
      flavor = "com.superlogical.terminal.shell",
      options = { command = argv },
    },
  }
  if err ~= nil then error(err, 0) end
end

rex.action{
  name = "open_project",
  title = "Open Project…",
  run = function(ctx)
    float{ scripts .. "rex-open-project.bash", ctx.client_id or "" }
  end,
}
rex.bind("ctrl+a>o", "open_project")

local terminal = "com.superlogical.terminal"

local function foreground(block_id)
  local process = rex.block.call(terminal, "process", { block_id = block_id })
  return process and process.foreground or {}
end

rex.action{
  name = "new_agent",
  title = "New Agent",
  run = function(ctx)
    local cwd = foreground(ctx.block_id).cwd
    local _, err = rex.session.new_window{
      window_label = "agent",
      focus = true,
      layout = rex.layout.block{
        flavor = terminal .. ".shell",
        -- Kept open so an error, such as an untrusted repo, stays readable.
        options = {
          command = { scripts .. "rex-new-agent.bash", cwd },
          cwd = cwd,
          exit = { on_completion = false },
        },
      },
    }
    if err ~= nil then error(err, 0) end
  end,
}
rex.bind("ctrl+a>n", "new_agent")
