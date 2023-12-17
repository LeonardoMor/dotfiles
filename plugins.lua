local plugins = {
  {
    "williamboman/mason.nvim",
    dependencies = "williamboman/mason-lspconfig.nvim",
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
        -- "dockerfile-language-server",
        -- "json-lsp",
        "python-lsp-server",
        "prettier",
        "stylua",
        "shfmt",
      },
    },
    cmd = {
      "Mason",
      "MasonInstall",
      "MasonUpdate",
      "MasonUninstall",
      "MasonUninstallAll",
      "MasonLog",
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
    cmd = {
      "TSUpdate",
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "nvimtools/none-ls.nvim",
      config = function()
        require "custom.configs.none-ls"
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
        portal_url = "https://codeium.delllabs.net",
        api_url = "https://codeium.delllabs.net/_route/api_server",
      }
    end,
    event = "VeryLazy",
  },
  {
    "windwp/nvim-autopairs",
    dependencies = { "hrsh7th/nvim-cmp" },
    event = "InsertEnter",
    config = function()
      require "custom.configs.nvim-autopairs"
    end,
  },
  -- {
  --   "jackMort/ChatGPT.nvim",
  --   event = "VeryLazy",
  --   dependencies = {
  --     "MunifTanjim/nui.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "nvim-telescope/telescope.nvim",
  --   },
  --   config = function()
  --     require("chatgpt").setup {
  --       api_key_cmd = "pass show api/tokens/openai",
  --     }
  --   end,
  -- },
}

return plugins
