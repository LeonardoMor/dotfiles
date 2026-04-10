    {
        'nvim-treesitter/nvim-treesitter',
        main = 'nvim-treesitter',
        branch = 'main',
        init = function()
            vim.api.nvim_create_autocmd('FileType', {
                callback = function()
                    pcall(vim.treesitter.start)
                    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end,
            })

            local ensureInstalled = {
                'bash',
                'diff',
                'gitattributes',
                'gitcommit',
                'git_config',
                'git_rebase',
                'go',
                'gotmpl',
                'html',
                'hyprlang',
                'jq',
                'json',
                'lua',
                'luadoc',
                'make',
                'markdown',
                'vim',
                'vimdoc',
                'xml',
            }
            local alreadyInstalled = require('nvim-treesitter.config').get_installed()
            local parsersToInstall = vim.iter(ensureInstalled)
                :filter(function(parser)
                    return not vim.tbl_contains(alreadyInstalled, parser)
                end)
                :totable()
            require('nvim-treesitter').install(parsersToInstall)
        end,
    }
{{- /*
vim: filetype=lua.gotmpl
*/ -}}
