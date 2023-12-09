local null_ls = require "null-ls"

local sources = {
  null_ls.builtins.formatting.black.with({ filetypes = { "python" } }),
  -- null_ls.builtins.diagnostics.mypy,
  null_ls.builtins.diagnostics.ruff.with({ filetypes = { "python" } }),
  -- null_ls.builtins.diagnostics.shellcheck,
  null_ls.builtins.formatting.shfmt.with({ filetypes = { "sh", "zsh" } }),
  -- null_ls.builtins.formatting.prettier,
  null_ls.builtins.formatting.stylua,
}

null_ls.setup {
  debug = true,
  sources = sources,
}
