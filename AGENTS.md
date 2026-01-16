# Agent Guidelines for dotfiles Repository

## Build/Lint/Test Commands

- **Deploy dotfiles**: `chezmoi apply`
- **Format Lua**: `stylua .` (2-space indent, 160 width, single quotes)
- **Format JS/JSON**: `biome format --write .` (4-space indent)
- **Format prose**: `prettier --write .` (prose wrap always)
- **No test framework** - manual testing via `chezmoi apply --dry-run`. If
  `.chezmoi.toml.tmpl` was changed, run `chezmoi init` to catch config errors.
  Then run `chezmoi apply --dry-run`.

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

- Use `#!/usr/bin/env bash`
- Error handling: `die()` or `emit` functions with levels (i|e|w|f)
- Functions: kebab-case naming `function-name`
- Local variables: snake_case naming `local var_name`
- Global variables: ALL_CAPS naming `GLOBAL_VAR_NAME`
- Global constants: ALL_CAPS naming `GLOBAL_CONST_NAME`
- 4-space indent
- Prefer `command || action` over `if ! command; then action; fi`
- Prefer bashisms over POSIX. We like bash, and we're not afraid of using its
  features. For example, use `[[` instead of `[` or `test`. Do not quote
  variables in `[[` expressions, and so on.
- Prefer long-form options for commands where available (e.g., --raw-output over -r)

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
- Reference: https://chezmoi.io

### General

- Do not commit any changes unless explicitly requested
- When told to commit, use semantic commit messages
- No comments unless essential
- Follow existing patterns in each file type
- Use absolute paths for file operations
- Store command arguments in array-like variables
