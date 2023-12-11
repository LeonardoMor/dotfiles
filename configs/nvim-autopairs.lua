local npairs = require('nvim-autopairs')
-- local Rule = require('nvim-autopairs.rule')
-- local cond = require('nvim-autopairs.conds')
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
local cmp = require('cmp')

opts = {
  fast_wrap = {},
  disable_filetype = { "TelescopePrompt", "vim" },
}

npairs.setup(opts)
cmp.event:on(
  'confirm_done',
  cmp_autopairs.on_confirm_done({
    filetypes = {
      sh = false
    }
  })
)