return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    lazy = false,
    version = "main",
    config = function ()
    local ts = require("nvim-treesitter")
    local ensure_installed = {
      "bash",
      "zsh",
      "dockerfile",
      "git_config",
      "git_rebase",
      "gitattributes",
      "gitcommit",
      "gitignore",
      "go",
      "gomod",
      "gosum",
      "json",
      "toml",
      "yaml",
      "make",
      "markdown",
      "python",
      "lua"
    }

    ts.install(ensure_installed)

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("EnableTreesitterHighlighting", { clear = true }),
      desc = "Try to enable tree-sitter syntax highlighting",
      pattern = "*", -- run on *all* filetypes
      callback = function()
        pcall(function() vim.treesitter.start() end)
      end,
    })


    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-context',
    opts = {
      enable = true,
    },
  },
}
