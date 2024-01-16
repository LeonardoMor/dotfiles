local M = {}
local fn = vim.fn

M.general = {
  n = {
    ["<C-d>"] = { "<C-d>zz", "Scroll down half page and center the cursor vertically" },
    ["<C-u>"] = { "<C-u>zz", "Scroll up half page and center the cursor vertically" },
    ["<leader>s"] = { [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], "Replace word under cursor" },
    ["J"] = { "mzJ`z", "Append the next line to the current but don't move the cursor" },
    ["n"] = { "nzzzv", "Next search result and center the cursor vertically" },
    ["N"] = { "Nzzzv", "Previous search result and center the cursor vertically" },
    ["<leader>y"] = { '"+y', "Copy to system clipboard" },
    ["<leader>Y"] = { '"+Y', "Copy to system clipboard" },
    ["<S-Insert>"] = { '"+p', "Paste from system clipboard" },
  },
  i = {
    ["<S-Insert>"] = { '"+p', "Paste from system clipboard" },
  },
  v = {
    ["J"] = { ":m '>+1<CR>gv=gv", "Move current selection down" },
    ["K"] = { ":m '<-2<CR>gv=gv", "Move current selection up" },
    ["<leader>y"] = { '"+y', "Copy to system clipboard" },
    ["<S-Insert>"] = { '"+p', "Paste from system clipboard" },
  },
  -- keeping this as it might be useful, but NvChad already handles this in the way I want
  -- x = {
  --   ["<leader>p"] = { '"_pdP', "Paste and hold what was just pasted, so I can be pasted again" },
  -- },
}

-- M.aerial = {
--   n = {
--     ["<F8>"] = { "<cmd>AerialToggle<CR>", "Toggle aerial" },
--   },
-- }
M.outline = {
  n = {
    ["<F8>"] = { "<cmd>Outline<CR>", "Toggle outline" },
  },
}

M.quickfix = {
  n = {
    ["<C-j>"] = { "<cmd>cnext<CR>zz", "Next quickfix item" },
    ["<C-k>"] = { "<cmd>cprev<CR>zz", "Previous quickfix item" },
  },
}

M.tmux = {
  n = {
    ["<C-h>"] = { "<cmd> TmuxNavigateLeft<CR>", "Window left" },
    ["<C-l>"] = { "<cmd> TmuxNavigateRight<CR>", "Window right" },
    ["<C-j>"] = { "<cmd> TmuxNavigateDown<CR>", "Window down" },
    ["<C-k>"] = { "<cmd> TmuxNavigateUp<CR>", "Window up" },
  },
}

M.codeium = {
  i = {
    ["<A-l>"] = {
      function()
        return fn["codeium#Accept"]()
      end,
      "Accept completion",
      opts = { expr = true },
    },
    ["<A-]>"] = {
      function()
        return fn["codeium#CycleCompletions"](1)
      end,
      "Cycle completions forwards",
      opts = { expr = true },
    },
    ["<A-[>"] = {
      function()
        return fn["codeium#CycleCompletions"](-1)
      end,
      "Cycle completions backwards",
      opts = { expr = true },
    },
    ["<C-l>"] = {
      function()
        return fn["codeium#Clear"]()
      end,
      "Clear completion",
      opts = { expr = true },
    },
  },
}

return M
