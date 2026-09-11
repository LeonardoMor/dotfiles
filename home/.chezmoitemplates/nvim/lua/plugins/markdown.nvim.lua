    {
        'MeanderingProgrammer/markdown.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        config = function()
            require('render-markdown').setup {}
        end,
        -- cond = function()
        --   local path = vim.fn.expand '%:p'
        --   return not string.match(path, '^' .. vim.fn.expand '~/Projects/Codice' .. '/')
        -- end,
        cmd = { 'RenderMarkdown' },
        ft = { 'markdown' },
    }
{{- /*
vim: filetype=lua.gotmpl
*/ -}}
