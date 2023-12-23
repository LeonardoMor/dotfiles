vim.api.nvim_create_autocmd("BufEnter", {
  desc = "Pin the buffer to any window that is fixed width or height",
  callback = function(args)
    local stickybuf = require "stickybuf"
    if not stickybuf.is_pinned() and (vim.wo.winfixwidth or vim.wo.winfixheight) then
      stickybuf.pin()
    end
  end,
})

require("stickybuf").setup()
