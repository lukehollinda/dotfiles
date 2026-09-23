return {
  {
    --- Inline Markdown rendering
    ft = 'markdown',
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' },

    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      code = {
        enabled = true,
      },
    },
    -- Read by the markdown syntax file, so it has to be set before any markdown
    -- buffer loads rather than when this plugin does
    init = function()
      vim.g.markdown_fenced_languages = {
        "bash", "sh", "lua", "json", "yaml", "diff", "python", "go"
      }
    end,
  },
  {
    --- Markdown Preview
    'davidgranstrom/nvim-markdown-preview',
    config = function ()
    end,
  }
}
