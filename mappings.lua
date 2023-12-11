local M = {}

M.tmux = {
  n = {
    ["<C-h>"] = { "<cmd> TmuxNavigateLeft<CR>", "window left" },
    ["<C-l>"] = { "<cmd> TmuxNavigateRight<CR>", "window right" },
    ["<C-j>"] = { "<cmd> TmuxNavigateDown<CR>", "window down" },
    ["<C-k>"] = { "<cmd> TmuxNavigateUp<CR>", "window up" },
  },
}

vim.g.codeium_disable_bindings = 1
M.codeium = {
  i = {
    ["<A-l>"] = { 
      function() 
        return vim.fn['codeium#Accept']() 
      end, 
      "accept completion",
      opts = { expr = true }
    },
    ["<A-]>"] = { 
      function() 
        return vim.fn['codeium#CycleCompletions'](1) 
      end, 
      "cycle completions forward",
      opts = { expr = true }
    },
    ["<A-[>"] = { 
      function() 
        return vim.fn['codeium#CycleCompletions'](-1) 
      end, 
      "cycle completions backward",
      opts = { expr = true }
    },
    ["<C-]>"] = { 
      function() 
        return vim.fn['codeium#Clear']() 
      end, 
      "clear completion",
      opts = { expr = true }
    },
  },
}

return M
