return {
  'stevearc/conform.nvim',
  dependencies = 'zapling/mason-conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>ff',
      function()
        require('conform').format {
          async = true,
          lsp_fallback = true,
        }
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
    {
      '<leader>fi',
      function()
        require('conform').format {
          formatters = { 'injected' },
          timeout_ms = 3000,
        }
      end,
      mode = '',
      desc = '[F]ormat [I]njected languages',
    },
    {
      '<leader>tf',
      '<cmd>FormatToggle<cr>',
      desc = '[T]oggle [F]ormat on save',
    },
  },
  config = function()
    local function show_notification(message, level)
      local notify = require('fidget').notify
      notify(message, vim.log.levels[level], { annote = 'conform.nvim' })
    end

    vim.api.nvim_create_user_command('FormatToggle', function(args)
      local is_global = not args.bang
      if is_global then
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        if vim.g.disable_autoformat then
          show_notification('Format on save disabled', 'INFO')
        else
          show_notification('Format on save enabled', 'INFO')
        end
      else
        vim.b.disable_autoformat = not vim.b.disable_autoformat
        if vim.b.disable_autoformat then
          show_notification('Format on save disabled for this buffer', 'INFO')
        else
          show_notification('Format on save enabled for this buffer', 'INFO')
        end
      end
    end, {
      desc = 'Toggle format on save',
      bang = true,
    })

    require('conform').setup {
      notify_on_error = false,
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        return {
          timeout_ms = 500,
          lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
        }
      end,
      formatters_by_ft = {
        html = { 'prettierd', 'prettier', stop_after_first = true },
        lua = { 'stylua' },
        json = { 'biome' },
        markdown = { 'prettierd', 'prettier', stop_after_first = true },
        ['*'] = { 'injected' },
        ['_'] = { 'injected' },
{{- if ne .chezmoi.os "windows" }}
        awk = { 'prettier' },
        go = { 'gofmt' },
        -- jq = { 'jqfmt' },
        python = { 'isort', 'black' },
        rst = { 'prettier' },
        sh = { 'shfmt' },
        xml = { 'xmllint' },
{{- end }}
      },
      formatters = {
{{- if ne .chezmoi.os "windows" }}
        -- jqfmt = {
        --   command = os.getenv 'HOME' .. '/go/bin/jqfmt',
        --   args = { '-ob', '-ar', '-op', 'pipe' },
        -- },
        isort = {
          prepend_args = { '--profile', 'black' },
        },
        shfmt = {
          prepend_args = { '--case-indent', '--indent', '0' },
        },
{{- end }}
        injected = {
          options = {
            lang_to_ext = {
              json = 'json',
              markdown = 'md',
{{- if ne .chezmoi.os "windows" }}
              awk = 'awk',
              bash = 'sh',
              c_sharp = 'cs',
              elixir = 'exs',
              go = 'gofmt',
              javascript = 'js',
              julia = 'jl',
              latex = 'tex',
              python = 'py',
              rst = 'rst',
              ruby = 'rb',
              rust = 'rs',
              teal = 'tl',
              typescript = 'ts',
              xml = 'xml',
{{- end }}
            },
          },
        },
        prettier = {
          options = {
            ft_parsers = {
              html = 'html',
              markdown = 'markdown',
            },
          },
        },
      },
    }
  end,
}
