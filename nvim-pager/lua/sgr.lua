-- delta writes colour as SGR escapes and erase-in-line, and nothing else, so
-- the highlights can be read straight off each line. Rendering through a
-- terminal instead would expand tabs to spaces and swallow control bytes, and
-- these are the lines a yank hands back.
local M = {}

local ns = vim.api.nvim_create_namespace('pager.sgr')
local groups = {}

local function colour(n)
  return vim.g['terminal_color_' .. n]
end

-- A reusable highlight per distinct appearance; the key doubles as its name.
local function group_for(state)
  local key = table.concat({
    state.fg or '', state.bg or '',
    state.bold and 'b' or '', state.italic and 'i' or '', state.underline and 'u' or '',
  }, ':')
  if key == '::::' then
    return nil
  end
  if not groups[key] then
    local name = 'PagerSgr' .. key:gsub('%W', '')
    vim.api.nvim_set_hl(0, name, {
      fg = state.fg,
      bg = state.bg,
      bold = state.bold,
      italic = state.italic,
      underline = state.underline,
    })
    groups[key] = name
  end
  return groups[key]
end

-- Returns a fresh state so already-emitted segments keep the one they had.
local function apply(state, params)
  local new = vim.tbl_extend('force', {}, state)
  local codes = {}
  for n in params:gmatch('[0-9]+') do
    codes[#codes + 1] = tonumber(n)
  end
  if #codes == 0 then
    codes = { 0 }
  end

  local i = 1
  while i <= #codes do
    local c = codes[i]
    if c == 0 then
      new = {}
    elseif c == 1 then
      new.bold = true
    elseif c == 3 then
      new.italic = true
    elseif c == 4 then
      new.underline = true
    elseif c == 22 then
      new.bold = nil
    elseif c == 23 then
      new.italic = nil
    elseif c == 24 then
      new.underline = nil
    elseif c == 39 then
      new.fg = nil
    elseif c == 49 then
      new.bg = nil
    elseif c >= 30 and c <= 37 then
      new.fg = colour(c - 30)
    elseif c >= 40 and c <= 47 then
      new.bg = colour(c - 40)
    elseif c >= 90 and c <= 97 then
      new.fg = colour(c - 90 + 8)
    elseif c >= 100 and c <= 107 then
      new.bg = colour(c - 100 + 8)
    elseif c == 38 or c == 48 then
      local field = c == 38 and 'fg' or 'bg'
      if codes[i + 1] == 2 then
        new[field] = ('#%02x%02x%02x'):format(codes[i + 2] or 0, codes[i + 3] or 0, codes[i + 4] or 0)
        i = i + 4
      elseif codes[i + 1] == 5 then
        new[field] = colour(codes[i + 2] or 0)
        i = i + 2
      end
    end
    i = i + 1
  end
  return new
end

-- Strips the escapes from the buffer and re-applies them as extmarks. Delta's
-- erase-in-line only pads a row out to the terminal's width, which the window
-- supplies here, so it is dropped with the rest of the escape.
function M.render(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local marks = {}

  for row, line in ipairs(lines) do
    if line:find('\27', 1, true) then
      local state, text, pos = {}, {}, 1
      local width = 0

      while true do
        local s, e, params, final = line:find('\27%[([0-9;:]*)(%a)', pos)
        if not s then
          break
        end
        if s > pos then
          local chunk = line:sub(pos, s - 1)
          text[#text + 1] = chunk
          marks[#marks + 1] = { row - 1, width, { end_col = width + #chunk, hl_group = group_for(state) } }
          width = width + #chunk
        end
        if final == 'm' then
          state = apply(state, params)
        end
        pos = e + 1
      end

      local rest = line:sub(pos)
      if #rest > 0 then
        text[#text + 1] = rest
        marks[#marks + 1] = { row - 1, width, { end_col = width + #rest, hl_group = group_for(state) } }
        width = width + #rest
      end
      lines[row] = table.concat(text)
    end
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for _, m in ipairs(marks) do
    if m[3].hl_group then
      pcall(vim.api.nvim_buf_set_extmark, buf, ns, m[1], m[2], m[3])
    end
  end
end

return M
