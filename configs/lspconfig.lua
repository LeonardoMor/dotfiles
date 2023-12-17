local configs = require "plugins.configs.lspconfig"
local on_attach = configs.on_attach
local capabilities = configs.capabilities

local lspconfig = require "lspconfig"
local servers = {
  "awk_ls",
  "bashls",
  "dockerls",
  "lua_ls",
  "marksman",
  -- "grammarly", -- This has to use node 16, will be removed once they fix it
  -- "pylsp" -- We'll set this up separately
}
local home_dir = os.getenv("HOME")

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

lspconfig.grammarly.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  -- Workaround
  cmd = { home_dir .. "/bin/grammarlywo.sh" },
}

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
        black = { enabled = false },
        ruff = { enabled = false },
        memestra = { enabled = false },
      },
    },
  },
}
