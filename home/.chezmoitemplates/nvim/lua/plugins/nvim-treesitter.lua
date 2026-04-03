    {
        'nvim-treesitter/nvim-treesitter',
        main = 'nvim-treesitter',
	branch = 'main',
        init = function()
            local ensureInstalled = {
                'bash',
                'diff',
                'git_config',
                'git_rebase',
                'gitattributes',
                'gitcommit',
                'html',
                'hyprlang',
                'json',
                'jq',
                'lua',
                'luadoc',
                'markdown',
                'vim',
                'vimdoc',
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
