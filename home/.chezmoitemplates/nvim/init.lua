-- Set these before anything else
vim.g.have_nerd_font = true

-- [[ Install `lazy.nvim` plugin manager ]]
require 'config.lazy'

-- [[ Basic Keymaps ]]
vim.schedule(function()
  require 'mappings'
end)

-- [[ Basic Autocommands ]]
require 'autocmds'
