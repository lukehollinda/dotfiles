return {
    {
        --- Inline Markdown rendering
        'MeanderingProgrammer/render-markdown.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' },

        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {
            code = {
                enabled = true,
            },
        },
        config = function ()
            -- Code block rendering
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
