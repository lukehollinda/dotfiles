return {
    {
        --- Inline Markdown rendering
        'MeanderingProgrammer/render-markdown.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you prefer nvim-web-devicons

        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {
            code = {
                enabled = true,
            },
        },
        init = function ()
            -- Out of the blue was required to add this to fix code block rendering
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
