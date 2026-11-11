local M = {}

local home = os.getenv("HOME")
M.scripts = home .. "/dotfiles/bin/scripts/"
M.state_dir = home .. "/.local/state/rex"
M.terminal = "com.superlogical.terminal"

-- Terminals started from here get the login environment, which lacks the
-- folders ~/.zshrc adds to PATH.
local dotfiles_path = { home .. "/dotfiles/bin", home .. "/dotfiles/bin/scripts" }

function M.foreground(block_id)
  local process = rex.block.call(M.terminal, "process", { block_id = block_id })
  return process and process.foreground or {}
end

-- Runs an interactive script over the active tab, or over the part of a tab
-- given by bounds and window_id; the pane closes when it exits.
function M.float(argv, bounds, window_id)
  local _, err = rex.session.new_layer{
    window_id = window_id,
    bounds = bounds or { 0.1, 0.1, 0.8, 0.8 },
    focus = true,
    layout = rex.layout.block{
      flavor = M.terminal .. ".shell",
      options = { command = argv, path_prepend = dotfiles_path },
    },
  }
  if err ~= nil then error(err, 0) end
end

-- The window of a session view that holds a block, in any layer.
function M.window_of(view, block_id)
  for _, window in ipairs(view.windows) do
    for _, layer in ipairs(window.layers) do
      for _, block in ipairs(layer.blocks) do
        if block.block_id == block_id then return window end
      end
    end
  end
end

local function walk(node, block_id, path)
  if node.block_id then return node.block_id == block_id and node or nil end
  for _, side in ipairs{ "before", "after" } do
    table.insert(path, { node = node, side = side })
    local found = walk(node.split[side], block_id, path)
    if found then return found end
    table.remove(path)
  end
end

-- A block's layout node in its tiled layer, and the splits around it,
-- outermost first, each with the side the block is on. Nil for a block that is
-- not tiled.
function M.tiled_node(window, block_id)
  for _, layer in ipairs(window.layers) do
    if layer.kind == "tiled" then
      local path = {}
      local node = walk(layer.layout, block_id, path)
      if node then return node, path end
    end
  end
end

return M
