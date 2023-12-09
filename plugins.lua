local plugins = {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "black",
        -- "pyright",
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
  -- {
    -- https://github.com/zbirenbaum/copilot.lua
    -- https://raw.githubusercontent.com/github/copilot.vim/release/doc/copilot.txt
  --   "zbirenbaum/copilot.lua",
  --   cmd = "Copilot",
  --   event = "InsertEnter",
  --   config = function()
  --     require("copilot").setup({
  --       suggestion = { enabled = false },
  --       panel = { enabled = false },
  --     })
  --   end,
  -- },
  -- {
  --   "hrsh7th/nvim-cmp",
  --   dependencies = {
  --     {
  --       -- https://github.com/zbirenbaum/copilot-cmp
  --       "zbirenbaum/copilot-cmp",
  --       config = function ()
  --         require("copilot_cmp").setup()
  --       end
  --     },
  --   },
  --   config = function(_, opts)
  --     -- local conf = require "plugins.configs.cmp"
  --     table.insert(opts.sources, { name = "copilot", group_index = 2 })
  --     require'cmp'.setup(opts)
  --   end,
  -- },
  {
    -- https://raw.githubusercontent.com/tpope/vim-fugitive/master/doc/fugitive.txt
    "tpope/vim-fugitive",
    lazy = false,
  },
  {
    "tpope/vim-surround",
    lazy = false,
  },
  {
    "Exafunction/codeium.vim",
    config = function()
      vim.g.codeium_server_config = {
        portal_url = 'https://codeium.delllabs.net',
        api_url = 'https://codeium.delllabs.net/_route/api_server'
      }
      vim.g.codeium_disable_bindings = 1
      vim.keymap.set('i', '<M-l>', function () return vim.fn['codeium#Accept']() end, { expr = true })
      vim.keymap.set('i', '<M-]>', function() return vim.fn['codeium#CycleCompletions'](1) end, { expr = true })
      vim.keymap.set('i', '<M-[>', function() return vim.fn['codeium#CycleCompletions'](-1) end, { expr = true })
      vim.keymap.set('i', '<C-]>', function() return vim.fn['codeium#Clear']() end, { expr = true })
    end,
    event = "VeryLazy",
  },
  -- {
  --   'windwp/nvim-autopairs',
  --   event = "InsertEnter",
  --   config = function()
  --     require "custom.configs.nvim-autopairs"
  -- }
}

return plugins
