local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local null_ls = require "null-ls"

local opts = {
  sources = {
    null_ls.builtins.formatting.black.with({ filetypes = { "python" } }),
    -- null_ls.builtins.diagnostics.mypy,
    null_ls.builtins.diagnostics.ruff.with({ filetypes = { "python" } }),
    -- null_ls.builtins.diagnostics.shellcheck,
    null_ls.builtins.formatting.shfmt.with({ filetypes = { "sh", "zsh" } }),
    -- null_ls.builtins.formatting.prettier,
    null_ls.builtins.formatting.stylua,
  },
  on_attach = function(client, bufnr)
    if client.supports_method("textDocument/formatting") then
      vim.api.nvim_clear_autocmds({
        group = augroup,
        buffer = bufnr,
      })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr })
        end,
      })
    end
  end,
}

null_ls.setup(opts)
