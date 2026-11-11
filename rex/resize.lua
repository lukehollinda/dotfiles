local util = require("util")

-- A share of the window, so each step moves a border the same distance.
local resize_step = 0.025

local function first_block(node)
  return node.block_id or first_block(node.split.before)
end

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
    local window = util.window_of(view, ctx.block_id)
    local node, path = nil, nil
    if window then node, path = util.tiled_node(window, ctx.block_id) end
    if node == nil then return end

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
  rex.bind("resize/shift+" .. key, "resize_pane", { direction = direction })
end
rex.bind("resize/enter", "client.mode.exit")
