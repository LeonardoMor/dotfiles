    {
        'obsidian-nvim/obsidian.nvim',
        lazy = true,
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        ---@module 'obsidian'
        ---@type obsidian.config.ClientOpts
        opts = {
            wiki_link_func = "use_alias_only",
            workspaces = utils.vaults,
            completion = {
                blink = true,
                min_chars = 2,
            },
            ui = { enable = false },
            follow_url_func = function(url)
                {{- if eq .chezmoi.os "darwin" }}
                vim.fn.jobstart({"open", url})
                {{- else if eq .chezmoi.os "linux" }}
                vim.fn.jobstart({"xdg-open", url})
                {{- else if eq .chezmoi.os "windows" }}
                vim.fn.jobstart({"start", url})
                {{- end }}
            end,
            daily_notes = {
                folder = "Inbox/Journal",
                date_format = "%F",
                default_tags = {}
            },
            legacy_commands = false,
            footer = {
                enabled = true,
            },
        },
        event = function(self)
            return vim
                .iter(vim.tbl_map(function(workspace)
                    return {
                        'BufNewFile ' .. workspace.path .. '/**',
                        'BufReadPre ' .. workspace.path .. '/**',
                    }
                end, self.opts.workspaces))
                :flatten()
                :totable()
        end,
        cmd = { "Obsidian" }
        {{/*
            config = function()
                vim.api.nvim_create_autocmd('FileType', {
                    desc = 'Markdown Conceal for Obsidian vault files',
                    group = vim.api.nvim_create_augroup('MarkdownConceal', { clear = true }),
                    pattern = 'markdown',
                    callback = function()
                        local path = vim.fn.expand '%:p'
                        if string.match(path, '^' .. vim.fn.expand '~/source/repos/Codice' .. '/') then
                            vim.opt_local.conceallevel = 2
                        end
                    end,
                })
            end,
            */}}
        {{/*
            vim: filetype=lua.gotmpl
            */}}
    }
{{- /*
vim: filetype=lua.gotmpl
*/ -}}
