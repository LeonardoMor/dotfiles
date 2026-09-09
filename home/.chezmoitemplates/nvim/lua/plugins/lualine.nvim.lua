    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        opts = {
            sections = {
                lualine_a = { { 'mode', icon = '' } },
            },
            extensions = {
                'aerial',
                'fugitive',
                'lazy',
                {{- if ne .chezmoi.os "linux" }}
                'mason',
                {{- end }}
                'neo-tree',
                'quickfix',
                'trouble',
            },
            -- tabline = {
            --   lualine_a = { 'buffers' },
            --   lualine_z = { 'tabs' },
            -- },
        },
        event = 'BufWinEnter',
    }
{{- /*
vim: filetype=lua.gotmpl
*/ -}}
