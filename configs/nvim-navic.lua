local nvim_navic = require "nvim-navic"

local opts = {
  lsp = {
    auto_attach = true,
    preferece = { "pylsp", "bashls" },
  },
}

nvim_navic.setup(opts)
