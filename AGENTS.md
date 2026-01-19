# Agent Guidelines for dotfiles Repository

## Build/Lint/Test Commands

Building will be done manually via `chezmoi` commands. Linting is integrated
into the editor. Testing is done manually.

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
- In Bash, everything is a command. Commands return nothing but an exit code,
  but normally produce side effects in the form of writing to the standard file
  descriptors. Commands can interact with each other via these file descriptors,
  which make sense for interactive cli usage (oneliners). But for scripts, if
  the commands share the same environment, it is more elegant to have them
  interact with each other via variables.
- Given the previous point, for scripts, avoid creating unnecessary sub-shells.
  For example, prefer `while ..; do ..; done < <(command)` over
  `command | while ..; do ..; done`.
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
- Prefer long-form options for commands where available (e.g., --raw-output over
  -r)

#### `jq` scripts

- You can have sophisticated logic with pure `jq` scripts, with the help of
  `Bash`. Consider this construct:

```jq
#!/usr/bin/env -S bash --
#
# In `jq` comments can be continued with \. So the following line will be ignored by jq, but not by Bash.
# \
exec jq [OPTIONS] --from-file "$0" "$@"

# And so here you can add pure jq. For an example of this use case, see ~/bin/get-next-sink
```

- When filtering an array into a new array where each element is the
  corresponding filtered element of the original array, prefer `map(filter)`
  over `[.[] | filter]`.

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

### General

- Do not commit any changes unless explicitly requested
- When told to commit, use semantic commit messages
- No comments unless essential
- Follow existing patterns in each file type
- Use absolute paths for file operations
- Store command arguments in array-like variables
