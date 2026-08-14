---
name: bash
description: Use when writing, reviewing, or refactoring Bash scripts, shell wrappers, launchers, or automation involving argument handling, quoting, cleanup, error handling, or process management. Do not use for POSIX sh or throwaway interactive one-liners.
license: MIT
---

## Shebang

Always use the `env` form:

```bash
#!/usr/bin/env bash
```

For polyglot scripts that re-exec into another interpreter, use:

```bash
#!/usr/bin/env -S bash --
```

## Naming Conventions

| Element          | Style      | Example                    |
| ---------------- | ---------- | -------------------------- |
| Functions        | kebab-case | `install-package`          |
| Local variables  | snake_case | `local uname_out`          |
| Global variables | ALL_CAPS   | `LOCKFILE="/tmp/app.lock"` |
| Global constants | ALL_CAPS   | `MAX_RETRIES=3`            |

## Indentation

4 spaces. No tabs.

## Philosophy

In Bash, everything is a command. Commands return nothing but an exit code, but
produce side effects by writing to standard file descriptors. Commands can
interact with each other via these descriptors, which makes sense for
interactive oneliners. But for scripts, if commands share the same environment,
it is more elegant to have them interact via variables.

## Syntax Style

### Functions

Don't use the `function` keyword. Declare variables `local` unless the function
intentionally sets a global as its output (since Bash functions can't return
values):

Functions that print values for command substitution must keep stdout clean and send logs to stderr.

```bash
# BAD
function foo {
    i=foo
}

# GOOD
foo() {
    local i=foo
}
```

#### Globals as Return Values

Functions that produce a result set a global variable by convention. Name the
function `set-VARNAME` when its sole purpose is to populate that variable, and
document the output in the function's description:

```bash
set-OUTPUT_PATH() {
    # Sets OUTPUT_PATH to the output path derived from the input path.
    local input=$1
    OUTPUT_PATH=${input%.*}.out
}

set-OUTPUT_PATH "$1"
write-output "$OUTPUT_PATH"
```

### Block Statements

`then` goes on the same line as `if`; `do` goes on the same line as
`while`/`for`. Don't use semicolons to terminate statements -- they are only
for these control structure keywords:

```bash
# BAD
if true
then
    ...
fi

# GOOD
if true; then
    ...
fi
```

### Quoting

Use single quotes for static strings, double quotes for strings that need
expansion:

```bash
foo='Hello World'
bar="You are $USER"
```

All expansions that undergo word-splitting must be quoted. Where no splitting
occurs (assignments, `[[ ]]`), quotes are optional:

```bash
bar=$foo               # assignment: no splitting
if [[ -n $foo ]]; then # [[ ]]: no splitting
    echo "$foo"        # argument: quotes required
fi
```

Variables like `$$`, `$?`, `$#` never contain whitespace and don't need quotes.

## Error Handling

Never use `set -e`, `set -u`, or blanket `set -euo pipefail` as error handling. Check commands whose failure matters explicitly and fully own error handling in the script itself.

Never use `eval`. It opens code to injection and makes static analysis
impossible. Almost every use-case can be solved more safely with arrays,
indirect expansion, or proper quoting.

### Logging Function Pattern

A small logging function keeps severity, stderr output, and optional exits consistent. Define it in a standalone script, or source an existing shared implementation when the runtime environment provides one:

```bash
emit() {
    local level=${1:-} message=${2:-} exit_code=${3:-}

    case $level in
        i) printf 'INFO: %s\n' "$message" >&2 ;;
        w) printf 'WARNING: %s\n' "$message" >&2 ;;
        e) printf 'ERROR: %s\n' "$message" >&2 ;;
        f) printf 'FATAL: %s\n' "$message" >&2 ;;
        *)
            printf 'ERROR: Invalid log level: %s\n' "$level" >&2
            return 2
            ;;
    esac

    [[ -z $exit_code ]] || exit "$exit_code"
}
```

- All output goes to stderr.
- The optional third argument exits with that code.
- Invalid levels return `2` without recursive logging.

### Error Handling Patterns

Prefer `command || action` over `if ! command; then action; fi`:

```bash
# Single action on failure
some-command || emit e "Failed to run some-command"

# Chained fallback with fatal block
is-installed tool || install tool || {
    emit f "Unable to install tool" 1
}

# Guard clause with early exit
[[ -f $LOCKFILE ]] && exit 0

# Argument count check
(($# > 0)) || {
    echo "Usage: ${0##*/} <arg>" >&2
    exit 1
}

# Ensure preconditions
[[ -d $TARGET_DIR ]] || mkdir -p "$TARGET_DIR" || emit f "Unable to create $TARGET_DIR" 1
```

Always check fallible commands such as `cd`, `mkdir`, `mktemp`, and `cp` when their failure affects later behavior:

```bash
# BAD
cd /some/path
rm file

# GOOD
cd /some/path || exit 1
rm file
```

## Bashisms Over POSIX

Always prefer Bash builtins and keywords over external commands or `sh(1)`
syntax.

### Conditionals

Use `[[ ]]` instead of `[ ]` or `test`. Do not quote expansions inside `[[ ]]`:

```bash
[[ -f $LOCKFILE ]] && exit 0
[[ -d $DIR ]] || mkdir -p "$DIR" || exit 1
[[ -z $3 ]] || exit "$3"
```

Exception: quote the right-hand side of `==` or `!=` when you want literal
matching and the value could contain glob characters.

### Arithmetic

Use `(( ))` and `$(( ))` for numeric operations:

```bash
(($# > 0)) || exit 1
((retries++))
result=$((a + b))

# BAD
if [[ $a -gt $b ]]; then ...

# GOOD
if ((a > b)); then ...
```

### Sequences

Use Bash builtins for generating sequences, not `seq`:

```bash
# BAD
for f in $(seq 1 5); do ...

# GOOD
for f in {1..5}; do ...

# GOOD (variable bound)
for ((i = 0; i < n; i++)); do ...
```

### Command Substitution

Use `$(...)`, never backticks:

```bash
# BAD
foo=`date`

# GOOD
foo=$(date)
```

### Parameter Expansion

Prefer parameter expansion over external commands like `sed`, `awk`, `basename`:

```bash
name='bahamas10'

# BAD
prog=$(basename "$0")
nonumbers=$(echo "$name" | sed -e 's/[0-9]//g')

# GOOD
prog=${0##*/}
nonumbers=${name//[0-9]/}
```

Other useful expansions:

```bash
lower="${value,,}"
upper="${value^^}"
default="${var:-fallback}"

# Default assignment inside conditional
[[ ${result:="$(fallback-command)"} != "null" ]]
```

### Here-Strings

Use `<<<` to feed expansions as stdin instead of `echo ... |`:

```bash
count="$(jq 'length' <<<"$JSON_DATA")"
name="$(jq --raw-output '.name' <<<"$JSON_DATA")"
```

### The `read` Builtin

Use `read` to split strings and avoid forking external commands:

```bash
fqdn='host.example.com'
IFS=. read -r hostname domain tld <<<"$fqdn"
```

### Other Bashisms

```bash
# Regex matching
[[ $input =~ ^[0-9]+$ ]]

# Nameref
local -n ref=$1
ref="new value"
```

## Arrays

Use Bash arrays instead of space-separated strings:

```bash
# BAD
modules='json httpserver jshint'
for module in $modules; do ...

# GOOD
modules=(json httpserver jshint)
for module in "${modules[@]}"; do ...
```

### Indexed Arrays

Never assemble an executable command in one string. Store command arguments in arrays and execute with `"${array[@]}"`:

```bash
declare -a CMD=(
    docker run
    --rm
    --volume "$PWD:/work"
    --workdir /work
    "$IMAGE"
)
"${CMD[@]}"
```

Build arrays incrementally:

```bash
local -a args=("${BASE_ARGS[@]}")
args+=(--output "$OUTPUT_DIR" -- "$@")
"${args[@]}"
```

Passing prepared arguments to a command with `xargs` is also acceptable. This is useful for concise optional arguments; use null-delimited input (`xargs -0`) instead when arbitrary data must be preserved exactly.

```bash
xargs --verbose tool <<<"${verbose:+--verbose} ${output:+--output \"$output\"} \"$input\""
```

### Associative Arrays

Use `declare -A` for key-value mappings. Iterate with `"${!array[@]}"` for keys
and `"${array[$key]}"` for values:

```bash
declare -A configs
configs=(
    ["service-a"]="$(
        cat <<'EOF'
...multi-line content...
EOF
    )"
    ["service-b"]="$(
        cat <<'EOF'
...multi-line content...
EOF
    )"
)

for name in "${!configs[@]}"; do
    echo "${configs[$name]}" >"/tmp/${name}.conf"
done
```

## Iteration

### `for` vs `while`

`for` is for iterating over arguments or arrays. For line-oriented data, use
`while read -r`:

```bash
# BAD: captures all output into memory, breaks on spaces
users=$(awk -F: '{print $1}' /etc/passwd)
for user in $users; do ...

# GOOD: streaming, handles fields properly
while IFS=: read -r user _; do
    echo "$user"
done < /etc/passwd
```

### Listing Files

Never parse `ls`. Use globs:

```bash
# BAD
for f in $(ls); do ...

# GOOD
for f in *; do
    [[ -e $f ]] || continue
    ...
done
```

## Process Management

### Trap-Based Cleanup

Register cleanup functions with `trap`:

```bash
cleanup() {
    [[ -z ${lockfile:-} ]] || rm -f "$lockfile" 2>/dev/null
    [[ -z ${child_proc:-} ]] || pkill --exact "$child_proc" 2>/dev/null || true
}

trap cleanup EXIT INT TERM HUP QUIT
```

### Pre/Main/Post Pattern

For scripts that need setup and teardown. Capture original state in `pre`, and restore it in `post` only when capture succeeded:

```bash
#!/usr/bin/env bash

STATE_CAPTURED=false

pre() {
    ORIGINAL_STATE=$(read-state) || return 1
    STATE_CAPTURED=true
    prepare-state
}

main() {
    trap post EXIT INT TERM
    local -a cmd=(wrapper -- "$@")
    "${cmd[@]}"
}

post() {
    $STATE_CAPTURED || return
    restore-state "$ORIGINAL_STATE"
}

pre || exit 1
main "$@"
```

### Subshells for Scoped Operations

Use `( )` to isolate directory changes and other environment mutations:

```bash
for repo in "${REPOS[@]}"; do
    (
        cd "$WORKSPACE" || exit 1
        [[ -d $repo ]] || git clone "https://example.com/${repo}.git"
    )
done
```

### Avoiding Unnecessary Subshells

Prefer process substitution over pipes to avoid subshell variable scoping
issues:

```bash
# Preferred: loop body shares the caller's environment
while IFS= read -r line; do
    ((count++))
done < <(some-command)
echo "$count"

# Avoid: loop body runs in a subshell, variable changes are lost
some-command | while read -r line; do
    ((count++))
done
echo "$count" # always 0
```

## External Commands

### Useless `cat`

Don't use `cat` when the command reads files directly, or when redirection
works:

```bash
# BAD
cat file | grep foo

# GOOD
grep foo file

# Also GOOD
grep foo <file
```

### Command Options

Prefer long-form options where available:

```bash
jq --raw-output '.name'
curl --location --output /tmp/file "$URL"
```

## jq Integration

### Inline jq with Bash Variables

Parse JSON into a bash variable, then query it multiple times with `<<<`:

```bash
DATA="$(curl --silent "$API_URL")"
total="$(jq '.total' <<<"$DATA")"
name="$(jq --raw-output '.items[0].name' <<<"$DATA")"
```

Pass bash variables into jq with `--arg`:

```bash
jq --raw-output --arg name "$1" \
    '.items[] | select(.name == $name) | .id'
```

### The jq Polyglot Pattern

Create self-contained scripts that are both valid Bash and valid jq. The file
executes as Bash, then re-execs itself as a jq script:

```jq
#!/usr/bin/env -S bash --
#
# Description of what this script does
# Usage: some-command | this-script
# \
exec jq --arg var "$(bash-expression)" --from-file "$0" "$@"

# Pure jq code follows. The lines above are jq comments.
map(
    select(.type == "Node") |
    .props as $p |
    { id: .id, name: $p["node.name"] }
)
```

How it works:

1. `#!/usr/bin/env -S bash --` runs the file as Bash
2. Lines starting with `#` are comments in both Bash and jq
3. `# \` is a jq line-continuation, making jq skip the `exec` line
4. Bash hits `exec jq --from-file "$0"`, replacing itself with jq reading the
   same file
5. jq sees all the `#` lines as comments and executes the pure jq below

Use `--arg` to pass Bash-computed values into the jq context.

### jq Style

- Prefer `map(filter)` over `[.[] | filter]`
- Use `--raw-output` (long form)
- Use `--arg` to pass external values; never interpolate bash variables into jq
  filter strings

## sed Polyglot Pattern

Similar to the jq polyglot, sed scripts can be self-contained:

```sed
#!/usr/bin/env -S sed -i'' -Ef
#
# Description of what this script does

s/^\#?(SomeOption) +(yes|no)/\1 no/
```

## Argument Parsing

### Positional Arguments (most common)

For positional-only interfaces, validate `$#` before reading `$1`:

```bash
(($# > 0)) || {
    printf 'Usage: %s <target> [command...]\n' "${0##*/}" >&2
    exit 2
}

target=$1
shift
(($# == 0)) || "$@"
```

### getopts

For scripts that need option flags, use `getopts` with local `OPTIND`/`OPTARG`
to allow re-entrant use inside functions:

```bash
parse-args() {
    local opt OPTIND OPTARG
    while getopts 'p:v' opt; do
        case "$opt" in
            p) PREFIX="${OPTARG}/" ;;
            v) VERBOSE=1 ;;
            *) emit e "Unknown option: -${opt}" 1 ;;
        esac
    done
    shift $((OPTIND - 1))
    ARGS=("$@")
}
```

## Script Structure

A durable script usually follows this order:

1. Shebang and optional short usage comment.
2. Constants and defaults.
3. Logging and utility functions.
4. Argument parsing and discovery functions.
5. `pre`, `main`, and `post` when lifecycle behavior is needed.
6. A short final invocation.

### Typical Layout

```bash
#!/usr/bin/env bash

LOCKFILE="/tmp/myscript.lock"

[[ -f $LOCKFILE ]] && exit 0
(($# > 0)) || {
    echo "Usage: ${0##*/} <arg>" >&2
    exit 1
}

do-work() {
    local result
    result="$(some-command)" || emit e "Failed"
    echo "$result"
}

do-work "$@"
```

## Common Pitfalls

**`${f}` is not the same as `"$f"`:** braces don't quote. `${f}` still
undergoes word-splitting when unquoted. Use braces only for disambiguation
(`"${USER}s_home"`), not as a substitute for quoting.

**Don't add unnecessary comments.** The code should be self-explanatory. Only
add comments when the intent is genuinely non-obvious.

## Review Checklist

Before finishing, verify:

- The script uses Bash intentionally and has the correct shebang.
- No `set -e`, `set -u`, blanket `set -euo pipefail`, `eval`, command strings, parsed `ls`, or unhandled critical failures.
- Expanded variables used as command arguments are quoted.
- Optional command arguments are represented by arrays or safely prepared `xargs` input.
- `[[ ]]` and `(( ))` are used instead of legacy `[ ]` tests where Bash is available.
- Cleanup traps tolerate partial initialization.
- A non-trivial script has the smallest practical runnable check, such as `bash -n script.sh` plus a focused smoke test when behavior warrants it.

## References

- [YSAP Bash Style Guide](https://style.ysap.sh)
- [Pure Bash Bible](https://github.com/dylanaraps/pure-bash-bible)
- [BashGuide](https://mywiki.wooledge.org/BashGuide)
- [BashPitfalls](http://mywiki.wooledge.org/BashPitfalls)
- [BashFAQ](http://mywiki.wooledge.org/BashFAQ)
