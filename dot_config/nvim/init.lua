-- Set these before anything else
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

-- [[ Install `lazy.nvim` plugin manager ]]
require 'config.lazy'

-- [[ Setting options ]]
require 'options'

-- [[ Basic Keymaps ]]
vim.schedule(function()
  require 'mappings'
end)

-- [[ Basic Autocommands ]]
require 'autocmds'
