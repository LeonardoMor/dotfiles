local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local none_ls = require "none-ls"

local opts = {
  sources = {
    none_ls.builtins.formatting.black.with { filetypes = { "python" } },
    -- none_ls.builtins.diagnostics.mypy,
    none_ls.builtins.diagnostics.ruff.with { filetypes = { "python" } },
    -- none_ls.builtins.diagnostics.shellcheck,
    none_ls.builtins.formatting.shfmt.with { filetypes = { "sh", "zsh" } },
    -- none_ls.builtins.formatting.prettier,
    none_ls.builtins.formatting.stylua,
  },
  on_attach = function(client, bufnr)
    if client.supports_method "textDocument/formatting" then
      vim.api.nvim_clear_autocmds {
        group = augroup,
        buffer = bufnr,
      }
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format { bufnr = bufnr }
        end,
      })
    end
  end,
}

none_ls.setup(opts)
