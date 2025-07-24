return {
    {
    --- Inline Markdown rendering
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you prefer nvim-web-devicons

    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
    },
    {
    --- Markdown Preview
    'davidgranstrom/nvim-markdown-preview',
    config = {},
    }


}
