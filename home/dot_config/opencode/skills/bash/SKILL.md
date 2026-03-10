---
name: bash
description:
  Patterns and best practices for Bash scripting, covering error handling,
  naming conventions, arrays, jq integration, polyglot scripts, process
  management, and control flow idioms
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
set-FILTERED_INSTANCES() {
    # DESCRIPTION
    #   Stores a list of FQDNs from STACK in FILTERED_INSTANCES.
    #   If set, instances are filtered by INSTANCE_TYPE.
    local stack="$1" instances
    ...
    FILTERED_INSTANCES="$instances"
}

fuzzy-select() {
    # DESCRIPTION
    #   Interactive fuzzy pick. The selection is stored into the global
    #   SELECTION.
    local stack="$1"
    set-FILTERED_INSTANCES "$stack"
    SELECTION="$(fzf "${FZF_OPTS[@]}" <<<"$FILTERED_INSTANCES" | cut -d"$SEP" -f2)"
    [[ $SELECTION ]] || emit f "Nothing selected" 1
}
```

Multiple functions that set the same global can be chained:

```bash
p0-resolve "$1" || fuzzy-select "$1"
# Either way, SELECTION is now set
p0 ssh "$SELECTION"
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

Never use `set -e` or `set -euo pipefail`. Handle errors explicitly.

Never use `eval`. It opens code to injection and makes static analysis
impossible. Almost every use-case can be solved more safely with arrays,
indirect expansion, or proper quoting.

### Logging Function Pattern

Define a leveled logging function that optionally exits:

```bash
emit() {
    case "$1" in
        i) printf 'INFO: %s\n' "$2" >&2 ;;
        e) printf 'ERROR: %s\n' "$2" >&2 ;;
        w) printf 'WARNING: %s\n' "$2" >&2 ;;
        f) printf 'FATAL: %s\n' "$2" >&2 ;;
        *) emit e "Invalid log level" ;;
    esac
    [[ -z $3 ]] || exit "$3"
}
```

- All output to stderr
- Optional 3rd argument triggers `exit` with that code
- Recursive self-call on invalid level

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
[[ -d $TARGET_DIR ]] || mkdir -p "$TARGET_DIR"
```

Always check fallible commands like `cd`:

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
[[ -d $DIR ]] || mkdir -p "$DIR"
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
fqdn='computer1.daveeddy.com'
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

Store command arguments in arrays. Execute with `"${array[@]}"`:

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
for f in *; do ...
```

## Process Management

### Trap-Based Cleanup

Register cleanup functions with `trap`:

```bash
cleanup() {
    rm -f "$LOCKFILE" 2>/dev/null
    pkill --exact "$CHILD_PROC" 2>/dev/null || true
}

trap cleanup EXIT SIGINT SIGTERM SIGHUP SIGQUIT
```

### Pre/Main/Post Pattern

For scripts that need setup and teardown:

```bash
#!/usr/bin/env bash

pre() {
    systemctl --user stop some.service
}

main() {
    trap post EXIT INT TERM
    local -a cmd=(wrapper -- "$@")
    "${cmd[@]}"
}

post() {
    systemctl --user start some.service
}

pre
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
while read -r line; do
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

Most scripts use simple positional access:

```bash
TARGET="$1"
"$@"
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

## References

- [YSAP Bash Style Guide](https://style.ysap.sh)
- [BashGuide](https://mywiki.wooledge.org/BashGuide)
- [BashPitfalls](http://mywiki.wooledge.org/BashPitfalls)
- [BashFAQ](http://mywiki.wooledge.org/BashFAQ)
