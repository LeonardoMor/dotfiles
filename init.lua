-- vars to simplify
local opt = vim.opt
local g = vim.g
local api = vim.api
-- Relative line numbers on by default
opt.relativenumber = true
-- Keep system clipboard and nvim registries separated
opt.clipboard = ""
-- Don't keep search highlight, but highlight as you type
opt.hlsearch = false
opt.incsearch = true
-- Disable Codeium default bindings
g.codeium_disable_bindings = 1
-- Briefly highlight yanked text
api.nvim_create_autocmd("TextYankPost", {
  group = api.nvim_create_augroup("highlight_yank", {}),
  desc = "Hightlight selection on yank",
  pattern = "*",
  callback = function()
    vim.highlight.on_yank { higroup = "IncSearch", timeout = 125 }
  end,
})
