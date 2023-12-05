local plugins = {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "black",
        --        "pyright",
        -- "mypy",
        "ruff",
        "awk-language-server",
        "bash-debug-adapter",
        "bash-language-server",
        "shellcheck",
        "docker-compose-language-service",
        "dockerfile-language-server",
        -- "json-lsp",
        "python-lsp-server",
        "prettier",
        "stylua",
        "shfmt",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- defaults
        "vim",
        "lua",

        -- low level
        "c",
        "zig",

        -- scripting
        "bash",
        "awk",
        "python",
        "go",
        "perl",

        -- misc
        "json",
        "make",
        "markdown",
        "markdown_inline",
        "regex",
        "sql",
        "ssh_config",
        "xml",
        "yaml",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",

    dependencies = {
      "jose-elias-alvarez/null-ls.nvim",
      config = function()
        require "custom.configs.null-ls"
      end,
    },

    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end,
  },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },
}

return plugins
