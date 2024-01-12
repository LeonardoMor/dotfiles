local M = {}

M.general = {
  n = {
    ["<C-d>"] = { "<C-d>zz", "Scroll down half page and center the cursor vertically" },
    ["<C-u>"] = { "<C-u>zz", "Scroll up half page and center the cursor vertically" },
    ["<leader>s"] = { [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], "Replace word under cursor" },
  },
  v = {
    ["J"] = { ":m '>+1<CR>gv=gv", "Move current selection down" },
    ["K"] = { ":m '<-2<CR>gv=gv", "Move current selection up" },
  },
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
        return vim.fn["codeium#Accept"]()
      end,
      "Accept completion",
      opts = { expr = true },
    },
    ["<A-]>"] = {
      function()
        return vim.fn["codeium#CycleCompletions"](1)
      end,
      "Cycle completions forward",
      opts = { expr = true },
    },
    ["<A-[>"] = {
      function()
        return vim.fn["codeium#CycleCompletions"](-1)
      end,
      "Cycle completions backward",
      opts = { expr = true },
    },
    ["<C-]>"] = {
      function()
        return vim.fn["codeium#Clear"]()
      end,
      "Clear completion",
      opts = { expr = true },
    },
  },
}

return M
