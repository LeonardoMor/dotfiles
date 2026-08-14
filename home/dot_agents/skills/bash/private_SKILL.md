---
name: bash
description: Write, review, and refactor durable Bash scripts and shell wrappers. Use for Bash scripts, launchers, automation, argument parsing, quoting, cleanup, and process management; not for throwaway one-liners or POSIX sh.
license: MIT
---

# Bash scripting

Use pragmatic Bash, not POSIX `sh`, unless the task explicitly requires POSIX compatibility. Prefer clear control flow over clever shell tricks.

## Defaults

- Start durable scripts with `#!/usr/bin/env bash`.
- Use four-space indentation and no tabs.
- Use `kebab-case` functions, `snake_case` locals, and `ALL_CAPS` globals/constants.
- Use `[[ ... ]]`, `(( ... ))`, `$(...)`, functions, arrays, parameter expansion, and traps.
- Do **not** use `set -e`, `set -u`, or blanket `set -euo pipefail` as error handling. Check commands whose failure matters explicitly. Fully own error handling in the script itself.
- Do not use `eval` in code you control.

## The important rules

### Quote command arguments

Quote expansions when passing them as arguments:

```bash
mkdir -p "$target_dir" || exit 1
printf '%s\n' "$value"
```

Assignments and `[[ ]]` tests do not require normal argument quoting:

```bash
name=$value
if [[ -n $name ]]; then
    printf '%s\n' "$name"
fi
```

`${value}` only disambiguates the variable name; it does not quote it.

### Use arrays for commands and lists

Never assemble an executable command in one string. Use an array, especially when arguments are optional or contain user-controlled paths.

```bash
cmd=(tool --format json)
[[ -n ${output_dir:-} ]] && cmd+=(--output "$output_dir")
cmd+=(-- "$@")
"${cmd[@]}"
```

### Make failures visible

Use guards and explicit checks:

```bash
(($# > 0)) || {
    printf 'Usage: %s <input>\n' "${0##*/}" >&2
    exit 2
}

cd "$workdir" || exit 1
result=$(some-command) || {
    printf 'ERROR: some-command failed\n' >&2
    exit 1
}
```

For reusable scripts, send logs/errors to stderr so stdout remains composable.

```bash
emit() {
    case $1 in
        i) printf 'INFO: %s\n' "$2" >&2 ;;
        w) printf 'WARNING: %s\n' "$2" >&2 ;;
        e) printf 'ERROR: %s\n' "$2" >&2 ;;
        f) printf 'FATAL: %s\n' "$2" >&2 ;;
        *) printf 'ERROR: invalid log level\n' >&2 ;;
    esac

    [[ -z ${3:-} ]] || exit "$3"
}
```

### Prefer Bash builtins before subprocesses

Use parameter expansion for simple transformations instead of `basename`, `sed`, or `awk`:

```bash
program=${0##*/}
name_without_digits=${name//[0-9]/}
lowercase=${value,,}
default=${value:-fallback}
```

Use globs rather than parsing `ls`:

```bash
for file in "$config_dir"/*.conf; do
    [[ -e $file ]] || continue
    process-file "$file"
done
```

Use `while IFS= read -r line` for line-oriented input. If a loop changes a variable needed afterwards, avoid a pipeline subshell:

```bash
count=0
while IFS= read -r line; do
    ((count++))
done < <(some-command)
```

### Functions and state

Do not use the `function` keyword. Declare function variables `local`. A function that prints data must keep stdout clean; log to stderr.

```bash
read-config() {
    local config_file=$1
    [[ -r $config_file ]] || return 1
    <"$config_file"
}
```

When a function intentionally writes a global output, give that function a `set-` name and state the output in a brief comment.

### Cleanup and process lifecycle

Use tolerant cleanup traps for temp files, background processes, mounts, or altered state.

```bash
cleanup() {
    [[ -z ${tmp_file:-} ]] || rm -f "$tmp_file" 2>/dev/null
}

trap cleanup EXIT INT TERM HUP QUIT
```

For scripts with setup and teardown, use a readable `pre`, `main`, `post` lifecycle. Only restore state successfully captured during `pre`.

## Arguments and external tools

- For positional-only interfaces, validate `$#` before reading `$1`.
- For options, use `getopts`; use local `OPTIND` and `OPTARG` inside a parsing function.
- Prefer long options for external commands when they are available.
- Use `jq --arg` and `jq --raw-output`; do not interpolate Bash values into a jq program.
- Use here-strings instead of `echo "$value" | command` when feeding a value: `jq -r '.name' <<<"$json"`.

## Structure

A durable script usually has this order:

1. Shebang and optional short usage comment.
2. Constants/defaults.
3. Logging and utility functions.
4. Argument parsing and discovery functions.
5. `pre`, `main`, `post` when lifecycle behavior is needed.
6. A short final invocation.

## Review checklist

Before finishing, verify:

- The script uses Bash intentionally and has the correct shebang.
- No `eval`, command strings, parsed `ls`, or unhandled critical failures.
- Expanded variables used as arguments are quoted.
- Optional command arguments are represented by arrays.
- `[[ ]]` and `(( ))` are used rather than legacy `[ ]` tests where Bash is available.
- Traps tolerate partial initialization.
- A non-trivial script has one smallest practical runnable check (for example `bash -n script.sh`, plus a focused smoke test if behavior warrants it).
