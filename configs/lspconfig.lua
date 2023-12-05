local configs = require "plugins.configs.lspconfig"
local on_attach = configs.on_attach
local capabilities = configs.capabilities

local lspconfig = require "lspconfig"
local servers = {
  "awk_ls",
  "bashls",
  "dockerls",
  "lua_ls",
  -- "pylsp" -- We'll set this up separately
}

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

-- Set up pylsp
lspconfig.pylsp.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { "python" },
  settings = {
    pylsp = {
      plugins = {
        pycodestyle = { enabled = false },
        flake8 = { enabled = false },
        pylint = { enabled = false },
        pydocstyle = { enabled = false },
        yapf = { enabled = false },
        isort = { enabled = false },
        mypy = { enabled = false },
        pyflakes = { enabled = false },
        bandit = { enabled = false },
        black = { enabled = false},
        ruff = { enabled = false },
        memestra = { enabled = false },
      },
    },
  },
}
