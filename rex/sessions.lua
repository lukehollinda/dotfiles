local util = require("util")

-- Rex reports no session switches, so each keyboard switch records the session
-- it leaves, most recent first. Switches made with the mouse are not recorded.
local history_path = util.state_dir .. "/session-history"
rex.exec{ "/bin/mkdir", "-p", util.state_dir }

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

rex.action{
  name = "open_project",
  title = "Open Project…",
  run = function(ctx)
    remember(ctx.session_id)
    util.float{ util.scripts .. "rex-open-project.bash", ctx.client_id or "", history_path }
  end,
}
