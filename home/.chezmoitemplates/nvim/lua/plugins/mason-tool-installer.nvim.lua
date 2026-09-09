    {
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        lazy = true,
        opts = {
            {{- if eq .chezmoi.os "windows" }}
            ensure_installed = require 'custom.tooling',
            {{- else }}
            -- No Homebrew formula: retain only the XML server as a macOS fallback.
            ensure_installed = { 'lemminx' },
            {{- end }}
            auto_update = true,
        },
    }
{{- /*
vim: filetype=lua.gotmpl
*/ -}}
