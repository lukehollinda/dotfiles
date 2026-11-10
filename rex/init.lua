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

-- The splits around a block, outermost first, with the side the block is on.
local function enclosing_splits(node, block_id, path)
  if node.block_id then return node.block_id == block_id end
  for _, side in ipairs{ "before", "after" } do
    table.insert(path, { node = node, side = side })
    if enclosing_splits(node.split[side], block_id, path) then return true end
    table.remove(path)
  end
  return false
end

local function first_block(node)
  return node.block_id or first_block(node.split.before)
end

-- A share of the window, so each step moves a border the same distance.
local resize_step = 0.025

-- Like tmux resize-pane: moves the pane's right (or bottom) border in the
-- direction given, or its left (or top) border when the pane is at that edge.
rex.action{
  name = "resize_pane",
  title = "Move Pane Border",
  args = { direction = "string" },
  repeats = true,
  run = function(ctx, args)
    local horizontal = args.direction == "left" or args.direction == "right"
    local orientation = horizontal and "horizontal" or "vertical"
    local sign = (args.direction == "left" or args.direction == "up") and -1 or 1
    local view, err = rex.session.view{}
    if err ~= nil then error(err, 0) end
    for _, window in ipairs(view.windows) do
      for _, layer in ipairs(window.layers) do
        local path = {}
        if layer.kind == "tiled" and enclosing_splits(layer.layout, ctx.block_id, path) then
          local chosen
          for i = #path, 1, -1 do
            if path[i].node.split.direction == orientation then
              chosen = chosen or path[i]
              if path[i].side == "before" then chosen = path[i] break end
            end
          end
          if chosen == nil then return end
          local split = chosen.node.split
          local extent = chosen.node.rect[horizontal and 3 or 4]
          local ratio = math.min(0.95, math.max(0.05, split.ratio + sign * resize_step / extent))
          local _, resize_err = rex.session.resize_pane{
            direction = orientation,
            before_block_id = first_block(split.before),
            after_block_id = first_block(split.after),
            ratio = ratio,
          }
          if resize_err ~= nil then error(resize_err, 0) end
          return
        end
      end
    end
  end,
}

-- tmux's bind -r: after the prefix, the same keys keep resizing until escape
-- or enter.
rex.action{
  name = "resize_pane_and_repeat",
  title = "Move Pane Border and Keep Resizing",
  args = { direction = "string" },
  run = function(ctx, args)
    local _, err = rex.invoke("resize_pane", { direction = args.direction })
    if err ~= nil then error(err, 0) end
    rex.client.queue("client.mode.enter", { name = "resize" })
  end,
}

rex.mode("resize", { exclusive = true })
for key, direction in pairs{ h = "left", j = "down", k = "up", l = "right" } do
  rex.bind("ctrl+a>shift+" .. key, "resize_pane_and_repeat", { direction = direction })
  rex.bind("resize/shift+" .. key, "resize_pane", { direction = direction })
end
rex.bind("resize/enter", "client.mode.exit")

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
