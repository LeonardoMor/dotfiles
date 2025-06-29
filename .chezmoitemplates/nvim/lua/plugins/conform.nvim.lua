return {
  'stevearc/conform.nvim',
  -- dependencies = 'zapling/mason-conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>ff',
      function()
        require('conform').format({ async = true }, function(err)
          if not err then
            local mode = vim.api.nvim_get_mode().mode
            if vim.startswith(string.lower(mode), 'v') then
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
            end
          end
        end)
      end,
      mode = '',
      desc = '[F]ormat buffer or range',
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

    ---@param bufnr integer
    ---@param ... string
    ---@return string
    local function first(bufnr, ...)
      local conform = require 'conform'
      for i = 1, select('#', ...) do
        local formatter = select(i, ...)
        if conform.get_formatter_info(formatter, bufnr).available then
          return formatter
        end
      end
      return select(1, ...)
    end

    local default_format_opts = { timeout_ms = 500, lsp_format = 'fallback' }

    require('conform').setup {
      default_format_opts = default_format_opts,
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true, gitcommit = true }
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat or disable_filetypes[vim.bo[bufnr].filetype] then
          return
        end
        return default_format_opts
      end,
      formatters_by_ft = {
        html = function(bufnr)
          return { first(bufnr, 'prettierd', 'prettier'), 'injected' }
        end,
        lua = { 'stylua' },
        json = { 'biome' },
        markdown = function(bufnr)
          return { first(bufnr, 'prettierd', 'prettier'), 'injected' }
        end,
        -- jq = { 'jqfmt' },
        python = { 'isort', 'black' },
        ['*'] = { 'injected' },
        ['_'] = { 'injected' },
{{- if ne .chezmoi.os "windows" }}
        awk = { 'prettier' },
        sh = { 'shfmt' },
        xml = { 'xmllint' },
{{- end }}
      },
      formatters = {
        -- jqfmt = {
        --   command = os.getenv 'HOME' .. '/go/bin/jqfmt',
        --   args = { '-ob', '-ar', '-op', 'pipe' },
        -- },
        isort = {
          prepend_args = { '--profile', 'black' },
        },
{{- if ne .chezmoi.os "windows" }}
        shfmt = {
          prepend_args = { '--case-indent', '--indent', '4' },
        },
{{- end }}
        injected = {
          options = {
            ignore_errors = false,
            lang_to_ft = {
              bash = 'sh',
            },
            lang_to_ext = {
              json = 'json',
              markdown = 'md',
{{- if ne .chezmoi.os "windows" }}
              awk = 'awk',
              bash = 'sh',
              -- c_sharp = 'cs',
              -- elixir = 'exs',
              -- go = 'gofmt',
              -- javascript = 'js',
              -- julia = 'jl',
              -- latex = 'tex',
              python = 'py',
              -- rst = 'rst',
              -- ruby = 'rb',
              -- rust = 'rs',
              -- teal = 'tl',
              -- typescript = 'ts',
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
  init = function()
    -- If you want the formatexpr, here is the place to set it
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
