# Agent Guidelines for dotfiles Repository

## Build/Lint/Test Commands

Building will be done manually via `chezmoi` commands. If no LSP are activated,
run:

```bash
opencode debug lsp diagnostics FILE
```

where `FILE` is an absolute path to a file that was modified.

## Code Style Guidelines

### Lua (Neovim config)

- Indentation: 2 spaces
- Line width: 160 characters
- Line endings: Unix
- Quotes: Single preferred (`'`)
- Call parentheses: None
- Error handling: `vim.api.nvim_echo` for user messages, `error()` for failures

### JavaScript/JSON

- Indentation: 4 spaces
- Follow Biome defaults

### Shell Scripts

- Prefer Bash. But when other tools are appropriate such as `sed`, `awk`, `jq`,
  use them.

#### Shared Utilities

The shared utils library is defined in `~/.chezmoitemplates/utils` and rendered
to `~/bin/utils.sh`. It provides the `emit()` logging function and
`change-dir()`. Source it in scripts that run after chezmoi has deployed:

```bash
source -p ~/bin utils.sh
```

In standalone scripts where chezmoi templates are not available (e.g.,
`.bootstrap/bootstrap.sh`), duplicate `emit()` directly.

#### Chezmoi Template Integration for Shell Scripts

Every `.tmpl` shell script starts with a platform/host guard:

```bash
{{- if eq .chezmoi.hostname "infinity" -}}
#!/usr/bin/env bash
...
{{- end -}}
```

Common guards:
- `{{ if eq .chezmoi.os "linux" -}}` -- Linux only
- `{{ if eq .chezmoi.os "darwin" -}}` -- macOS only
- `{{ if ne .chezmoi.os "windows" -}}` -- non-Windows
- `{{- if eq .chezmoi.hostname "infinity" -}}` -- specific host

Every template file ends with a vim modeline in a chezmoi comment:

```
{{/*
vim: filetype=sh.gotmpl
*/}}
```

Use `sh.gotmpl` for shell scripts, `jq.gotmpl` for jq polyglots, `gotmpl` for
pure templates.

Access chezmoi data inside scripts:

```bash
VAULTSDIR={{ .vaultsDir | quote }}
```

### Chezmoi Templates

- Delimiters: `{{` and `}}`
- Context: `.` initially refers to all Chezmoi data (see `chezmoi data`);
  changes in scoped constructs like `range` or `with`
- Template functions: Use sprig library functions
- Conditional logic: `{{- if condition }}...{{- end }}`
- Naming: camelCase (first letter lowercase)
- Data handling: `.chezmoidata` files cannot be templates. Set dynamic machine
  data in `.chezmoi.toml.tmpl` data section. Read dynamic environment data using
  `output`, `fromJson`, `fromYaml`, etc.
- To get what a template resolves to use `chezmoi execute-template --file FILE`.
  Replace `FILE` with the actual template file name.
- Reference: https://chezmoi.io

### Version Control

- Do not commit any changes unless explicitly requested
- When told to commit, use semantic commit messages
- Unless already tracked, keep `AGENTS.md` untracked

### General

- No comments unless essential
- Follow existing patterns in each file type
- Use absolute paths for file operations
- Store command arguments in array-like variables
