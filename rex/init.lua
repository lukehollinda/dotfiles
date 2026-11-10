rex.bind("ctrl+a>ctrl+a", "pane.send_key", { key = "ctrl+a" })
rex.bind("ctrl+a>w", "switch_tracked", { action = "session.switch" })

rex.bind("ctrl+a>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+a>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+a>k", "pane.focus", { direction = "up" })
rex.bind("ctrl+a>l", "pane.focus", { direction = "right" })

rex.bind("ctrl+a>v", "pane.split", { direction = "right" })
rex.bind("ctrl+a>s", "pane.split", { direction = "down" })
rex.bind("ctrl+a>c", "client.tab.new")
rex.bind("ctrl+a>=", "pane.balance")

local scripts = os.getenv("HOME") .. "/dotfiles/bin/scripts/"

-- Rex reports no session switches, so each keyboard switch records the session
-- it leaves, most recent first. Switches made with the mouse are not recorded.
local history_dir = os.getenv("HOME") .. "/.local/state/rex"
local history_path = history_dir .. "/session-history"
rex.exec{ "/bin/mkdir", "-p", history_dir }

local function read_history()
  local ids = {}
  local file = io.open(history_path)
  if file then
    for line in file:lines() do table.insert(ids, line) end
    file:close()
  end
  return ids
end

local function remember(session_id)
  local ids = { session_id }
  for _, id in ipairs(read_history()) do
    if id ~= session_id and #ids < 20 then table.insert(ids, id) end
  end
  local file = assert(io.open(history_path, "w"))
  file:write(table.concat(ids, "\n"), "\n")
  file:close()
end

rex.action{
  name = "switch_tracked",
  title = "Switch Session and Remember This One",
  args = { action = "string", args = "object?" },
  run = function(ctx, args)
    remember(ctx.session_id)
    rex.client.queue(args.action, args.args)
  end,
}

rex.action{
  name = "previous_session",
  title = "Go to Previous Session",
  run = function(ctx)
    local live = {}
    local list = rex.call("session.list")
    for _, session in ipairs(list and list.sessions or {}) do
      live[session.session_id] = true
    end
    for _, id in ipairs(read_history()) do
      if id ~= ctx.session_id and live[id] then
        remember(ctx.session_id)
        rex.client.queue("session.select", { session_id = id })
        return
      end
    end
  end,
}

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
    remember(ctx.session_id)
    float{ scripts .. "rex-open-project.bash", ctx.client_id or "" }
  end,
}
rex.bind("ctrl+a>o", "open_project")

local terminal = "com.superlogical.terminal"

local function foreground(block_id)
  local process = rex.block.call(terminal, "process", { block_id = block_id })
  return process and process.foreground or {}
end

local function tab_blocks(view, block_id)
  for _, window in ipairs(view.windows) do
    local ids, found = {}, false
    for _, layer in ipairs(window.layers) do
      for _, block in ipairs(layer.blocks) do
        table.insert(ids, block.block_id)
        found = found or block.block_id == block_id
      end
    end
    if found then return ids end
  end
  return {}
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

rex.action{
  name = "open_nvim",
  title = "Open nvim on This Checkout",
  run = function(ctx)
    local view, err = rex.session.view{}
    if err ~= nil then error(err, 0) end
    for _, id in ipairs(tab_blocks(view, ctx.block_id)) do
      if foreground(id).name == "nvim" then
        rex.session.focus_block{ block_id = id }
        return
      end
    end
    local _, split_err = rex.session.new_split{
      anchor_id = ctx.block_id,
      direction = "horizontal",
      side = "after",
      ratio = 0.4,
      focus = true,
      layout = rex.layout.block{
        flavor = terminal .. ".shell",
        options = { command = { "nvim", "." }, cwd = foreground(ctx.block_id).cwd },
      },
    }
    if split_err ~= nil then error(split_err, 0) end
  end,
}
rex.bind("ctrl+a>e", "open_nvim")

rex.action{
  name = "close_work",
  title = "Close Agent Tab or Session",
  run = function(ctx)
    float{ scripts .. "rex-close.bash", ctx.session_id, ctx.block_id }
  end,
}
rex.bind("ctrl+a>shift+x", "close_work")

rex.bind("ctrl+a>-", "previous_session")
rex.bind("cmd+k", "switch_tracked", { action = "session.switch" })
rex.bind("cmd+p", "switch_tracked", { action = "pane.go_to" })
for index = 1, 9 do
  rex.bind("cmd+[Digit" .. index .. "]", "switch_tracked",
    { action = "client.tab.goto", args = { index = index } })
end
