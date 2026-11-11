local util = require("util")

rex.action{
  name = "new_agent",
  title = "New Agent",
  run = function(ctx)
    local cwd = util.foreground(ctx.block_id).cwd
    local window, err = rex.session.new_window{
      window_label = "agent",
      focus = true,
      layout = rex.layout.block{
        flavor = util.terminal .. ".shell",
        -- Kept open so an error, such as an untrusted repo, stays readable.
        -- Interactive, so the agent and its hooks see what a terminal does.
        options = {
          command = { util.scripts .. "rex-new-agent.bash", cwd },
          cwd = cwd,
          interactive = true,
          exit = { on_completion = false },
        },
      },
    }
    if err ~= nil then error(err, 0) end
    -- The session's active window is not what the app shows, so ask the app.
    rex.client.queue("session.select", { session_id = ctx.session_id, window_id = window.window_id })
  end,
}

rex.action{
  name = "open_nvim",
  title = "Open nvim on This Checkout",
  run = function(ctx)
    local view, err = rex.session.view{}
    if err ~= nil then error(err, 0) end
    local window = util.window_of(view, ctx.block_id)
    for _, layer in ipairs(window and window.layers or {}) do
      for _, block in ipairs(layer.blocks) do
        if util.foreground(block.block_id).name == "nvim" then
          rex.session.focus_block{ block_id = block.block_id }
          return
        end
      end
    end
    local _, split_err = rex.session.new_split{
      anchor_id = ctx.block_id,
      direction = "horizontal",
      side = "after",
      ratio = 0.4,
      focus = true,
      layout = rex.layout.block{
        flavor = util.terminal .. ".shell",
        options = { command = { "nvim", "." }, cwd = util.foreground(ctx.block_id).cwd },
      },
    }
    if split_err ~= nil then error(split_err, 0) end
  end,
}

-- The pager floats over the Claude pane alone, so the rest of the tab stays
-- in view.
rex.action{
  name = "open_transcript",
  title = "Open Claude Transcript in nvim",
  run = function(ctx)
    local view, err = rex.session.view{}
    if err ~= nil then error(err, 0) end
    local window = util.window_of(view, ctx.block_id)
    local node = window and util.tiled_node(window, ctx.block_id)
    if node then
      util.float({ util.scripts .. "rex-transcript-tovim.bash", ctx.block_id }, node.rect, window.window_id)
    end
  end,
}

rex.action{
  name = "close_work",
  title = "Close Agent Tab or Session",
  run = function(ctx)
    util.float{ util.scripts .. "rex-close.bash", ctx.session_id, ctx.block_id }
  end,
}
