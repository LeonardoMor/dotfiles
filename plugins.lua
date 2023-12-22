local plugins = {
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
      {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
          "williamboman/mason.nvim",
          opts = {
            ensure_installed = {
              -- Python
              "yapf",
              "black",
              "ruff",
              "bash-debug-adapter",
              -- Shell
              "shellcheck",
              "shfmt",
              "prettier",
              "stylua",
            },
          },
        },
        opts = {
          ensure_installed = {
            "awk_ls",
            "bashls",
            "dockerls",
            "lua_ls",
            "marksman",
            "grammarly",
            "pyright",
          },
        },
      },
      {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        config = function()
          require "custom.configs.conform"
        end,
      },
    },
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end,
  },
  {
    "christoomey/vim-tmux-navigator",
    event = "VeryLazy",
  },
  {
    -- https://raw.githubusercontent.com/tpope/vim-fugitive/master/doc/fugitive.txt
    "tpope/vim-fugitive",
    dependencies = {
      "stevearc/stickybuf.nvim",
    },
    event = "InsertEnter",
  },
  {
    "tpope/vim-surround",
    event = "InsertEnter",
  },
  {
    "Exafunction/codeium.vim",
    config = function()
      vim.g.codeium_server_config = {
        portal_url = "https://codeium.delllabs.net",
        api_url = "https://codeium.delllabs.net/_route/api_server",
      }
    end,
    event = "InsertEnter",
  },
  {
    "windwp/nvim-autopairs",
    dependencies = { "hrsh7th/nvim-cmp" },
    event = "InsertEnter",
    config = function()
      require "custom.configs.nvim-autopairs"
    end,
  },
  {
    "stevearc/stickybuf.nvim",
    config = function()
      require("stickybuf").setup()
    end,
  },
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      "stevearc/stickybuf.nvim",
    },
  },
  {
    "hedyhli/outline.nvim",
    dependencies = {
      "onsails/lspkind.nvim",
    },
    event = "LspAttach",
    cmd = { "Outline", "OutlineOpen" },
    opts = {
      symbols = {
        icon_source = "lspkind",
      },
    },
  },
  -- {
  --   "stevearc/aerial.nvim",
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --     "nvim-tree/nvim-web-devicons",
  --     "stevearc/stickybuf.nvim",
  --   },
  --   event = "LspAttach",
  --   opts = {
  --     filter_kind = {
  --       "Class",
  --       "Constructor",
  --       "Enum",
  --       "Function",
  --       "Interface",
  --       "Module",
  --       "Method",
  --       "Struct",
  --       "Variable",
  --     },
  --   },
  -- },
  {
    "utilyre/barbecue.nvim",
    name = "barbecue",
    version = "*",
    dependencies = {
      {
        "SmiteshP/nvim-navic",
        config = function()
          require "custom.configs.nvim-navic"
        end,
      },
      "nvim-tree/nvim-web-devicons", -- optional dependency
    },
    opts = {
      attach_navic = false,
    },
    event = "LspAttach",
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
