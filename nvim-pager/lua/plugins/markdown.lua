-- Rendered Claude sessions are markdown, so the pager gets the editor's
-- markdown rendering. These point at the editor's checkouts with `dir` rather
-- than installing a second copy: they are large, the pager is kept lean, and a
-- duplicate would drift. If the editor does not have them the spec is empty,
-- so the pager still starts.
local editor = vim.fn.expand('~/.local/share/nvim')

local function installed(name)
  return vim.uv.fs_stat(editor .. '/lazy/' .. name) ~= nil
end

if not (installed('render-markdown.nvim') and installed('nvim-treesitter')) then
  return {}
end

return {
  {
    dir = editor .. '/lazy/render-markdown.nvim',
    ft = 'markdown',
    dependencies = {
      { dir = editor .. '/lazy/nvim-treesitter' },
      { dir = editor .. '/lazy/mini.icons' },
    },
    opts = {
      code = { enabled = true },
    },
  },
}
