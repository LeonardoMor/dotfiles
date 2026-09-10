# dotfiles

TLDR: to deploy on macOS or Linux (only Arch children for now supported), run

```bash
curl -fsSL https://github.com/LeonardoMor/dotfiles/raw/refs/heads/master/.bootstrap/bootstrap.sh | bash
```

<!-- prettier-ignore -->
> [!NOTE]
> Run `chezmoi apply` right after the command finishes.

## Generalities

`chezmoi` [documentation][chezmoi reference] is pretty excellent, I'll just put
here some stuff that I find useful to keep in mind.

There is a source directory, `$(chezmoi source-path)` and a target directory,
which is the directory that you want to manage and typically your `$HOME`.

At any given moment, `chezmoi` is considering 3 possible states:

- Source state: which is roughly the state of the `$(chezmoi source-path)` dir
- Target state: which is roughly the state of your home dir once everything is
  resolved and applied
- Current state: which is roughly the present state of your home dir

`chezmoi` produces the desired target state in function of two things:

- The source files and directories located at the source dir
- The `${XDG_CONFIG_HOME}/chezmoi/chezmoi.toml` file

There are a few ways in which you can excert control over the target state:

- [File and directory names](https://www.chezmoi.io/reference/source-state-attributes/)
- [File extensions](https://www.chezmoi.io/reference/source-state-attributes/)
- Scripts
- Templates
- The `${XDG_CONFIG_HOME}/chezmoi/chezmoi.toml` file

<!-- prettier-ignore -->
> [!NOTE]
> By default, anything on the source directory that has a name starting with
> `.` would be ignored by `chezmoi`. Consider these internal files for
> `chezmoi` to work. There would be examples along this document. The only
> exception is `.chezmoi.toml.tmpl`.

## `chezmoi.toml`, template of templates

You can use this file to manage machine to machine differences. The example
given in the docs is your git config. You might want to use your personal email
for your personal computer and your work email for your work computer. In my
case that is:

```
{{- if eq .chezmoi.hostname .workHost }}
    email = "work@email"
{{- else }}
    email = "personal@email"
{{- end }}
```

Now, it might be desirable to have a machine-specific `chezmoi.toml` files, so
you'd want to template it. You can create a file `.chezmoi.toml.tmpl` the source
dir that will produce a local `chezmoi.toml` once `chezmoi init` is run.

But some things on `chezmoi.toml` need to be variable. So you need some way to
indicate those instead of having them substituted by constants when running
`chezmoi init`.

All the functions (and syntax) from [text/template][template], and the [text
template functions from `sprig`][sprig] are available in `chezmoi`. So, one way
to do this is to use the `print` function. For example, this is the
configuration for the merge tool on the template:

```
[merge]
    command = "nvim"
    args = [
        "-O3",
        {{ print "{{.Destination}}" | quote }},
        {{ print "{{.Source}}" | quote }},
        {{ print "{{.Target}}" | quote }},
        "-c",
        "windo diffthis"
    ]
```

Which produces:

```toml
[merge]
command = "nvim"
args = [
  "-O3",
  "{{.Destination}}",
  "{{.Source}}",
  "{{.Target}}",
  "-c",
  "windo diffthis",
]
```

on the actual config file: `${XDG_CONFIG_HOME}/chezmoi/chezmoi.toml`
Alternatively, you can use a lot of `"{{"` and `"}}"` to achieve the same
result.

## Changing template delimiters

At times, you'll find that on a certain configuration file `{{` and `}}` are
needed as they are and not delimiting an action. To change the delimiters on
those files, you need to add some specific line. Here is an example of one such
line for a `.json` file:

```json
// chezmoi:template:left-delimiter="# [[" right-delimiter=]]
```

[Source](https://www.chezmoi.io/reference/templates/directives/#delimiters)

## Bootstrapping

Ideally, this system would allow you to have your machine ready to go by just
running a simple command and potentially answering some prompts.

This typically involves package installation.

`chezmoi` has support for encryption, but I've decided to use a separate
dedicated tool to handle secrets: [1Password][1]. `chezmoi` also integrates
support for 1Password so things very much just work.

Given this, there are only two pre-requisites to deploy these dotfiles:

- a package manager
- 1Password.

So I've created bootstrap scripts that would:

- install the package manager, if not installed already,
- install 1Password,
- deploy the dotfiles and install the packages via `chezmoi`.

## Package management: Linux and macOS

[Declarch](https://nixval.github.io/declarch/) owns desired package state. Chezmoi
owns its configuration and platform routing. Windows uses its winget manifest
and scripts.

### Sources and generated paths

`home/.chezmoitemplates/declarch/` contains the shared root/backend templates.
Thin destination templates generate them at:

- Linux: `~/.config/declarch/`
- macOS: `~/Library/Application Support/com.declarch.declarch/`

The `modules` **directory** at either destination is a symlink to
`home/.externally_modified/declarch/`. Those KDL files are the canonical,
editable package lists, not generated snapshots. A directory link survives
an editor's atomic replacement of individual module files; a file symlink may not.

| Module | Intent |
| --- | --- |
| `base.kdl` | Shared everyday tools |
| `coding.kdl` | Shared developer tools, language servers and formatters |
| `coding-linux.kdl`, `coding-darwin.kdl` | Platform-specific developer packages/names |
| `linux.kdl`, `darwin.kdl` | Platform-specific applications and utilities |
| `cachyos.kdl` | CachyOS packages; imported only on CachyOS |

The local `native` backend maps to Paru on Arch/CachyOS and Homebrew formulae
on macOS. Homebrew casks use `cask`; npm, pipx and macOS Cargo have separate
backends. Other Linux distributions need their own native backend and lists.

### Installation

Bootstrap installs backend prerequisites and Declarch before synchronizing
packages. To install Declarch explicitly, run from the repository root:

```bash
bash .bootstrap/install-declarch.sh
```

On Arch/CachyOS, the installer uses Paru to install the AUR `declarch-bin`
package. Installation stops if Paru fails; there is no Cargo fallback on Linux.

macOS 0.8.2 has a concrete upstream issue: `ProjectDirs::state_dir()` returns
`None`, causing `System does not support state directory`. The installer builds
the pinned `v0.8.2` tag with `.bootstrap/declarch-state-dir.patch`, using the
platform-local data directory as the fallback. On macOS, `state.json` therefore
lives alongside `declarch.kdl`. It installs the binary to `~/.local/bin` and
requires Homebrew Rust plus Apple's command-line build tools. This patch should
be retired once an upstream release fixes the lookup; do not replace the patched
binary with an unpatched 0.8.2 release. The actual macOS config path above follows
the source's bundle identifier, not the shorter example in the alpha docs.

Review Chezmoi's diff before applying; its `run_once_after` package installer
performs a real sync on first execution. To deploy only configuration, use
`chezmoi apply --exclude scripts` and then start a new login shell. Inspect
backend availability, configuration validity, and the package plan before syncing:

```bash
declarch info --doctor
declarch lint --mode validate
decl --dry-run sync --hooks
```

After reviewing the plan, run `decl sync --hooks`. The Linux service hook
configures greetd, Kanata, libvirt, kanata-switcher and OpenRazer when their
packages are installed; it may request sudo. Membership changes may require
logging in again. Native sync hooks also run when packages are already synchronized.

### Daily workflow and commits

Use `~/bin/decl` (available as `decl` after loading `.profile`):

```bash
decl install native:PACKAGE
decl install native:PACKAGE --module coding
decl edit coding
decl sync --hooks
update
```

Without `--module`, `decl install` records packages in `linux.kdl` on Linux or
`darwin.kdl` on macOS, under `home/.externally_modified/declarch/`. `native`
selects the package-manager backend, not the module. Use `--module` to choose
a shared or platform-specific coding module explicitly.

The `decl` wrapper forwards to the real `declarch` and checks package-file changes
after modifying operations—even when an operation fails after editing a manifest. Dry runs,
diff previews and help do not commit. Native `post-sync`/`on-failure` hooks call
the same helper; the wrapper covers install, edit and upgrade paths where
upstream does not dispatch those hooks. Wrapped native hooks defer their commit
until the outer command finishes. Calling `declarch` directly bypasses that
extra coverage, and its sync hooks still require `--hooks`.

Upstream does **not** honor `--dry-run` for `init`, `sync upgrade`, `sync cache` or
the hidden `self-update`, and `edit --create` (`-c`)/`--auto-format` can write before
checking preview flags. `decl` recognizes edit's `-p`/`-c` even in short-option
clusters and rejects unsafe preview combinations before invoking Declarch. It also adds
`--dry-run` to diff previews, since native `sync --diff --hooks` can execute hooks.
For subcommands, place hook flags after the subcommand: `decl sync prune --hooks`
or `decl sync update --hooks`, not `decl sync --hooks prune`. Native `switch`
updates installed packages/state but not manifests; edit the desired module too.

`chezmoi-declarch-commit` stages and commits **only changed KDL files** under the
two canonical Declarch source directories. It handles additions/deletions,
preserves unrelated staged files, honors Git signing, and never pushes. Failed
commits remain visible and can be retried with `chezmoi-declarch-commit`; do not
disable signing to hide a failure. Commits record desired configuration, not a
claim that a failed package operation completed successfully.

Use the predeclared module names above. To add a new module, create its canonical
file and add its import to the central root template, then apply the root config.
Do not edit the generated `declarch.kdl` or run `init`/`sync import` over it:
upstream may write imports into that generated file, which Chezmoi would replace.
State, caches and full installed-package exports are deliberately not committed.

To remove a package, edit its module, inspect `decl --dry-run sync prune`, then
run `decl sync prune` only after reviewing removals. Ordinary sync is additive;
orphans are kept. Pruning is an explicit, reviewed operation, not unattended
cleanup. Paru upgrades use full `-Syu`, never a partial
`pacman -Sy` refresh.

### Coding tooling ownership

Linux/macOS coding lists provision native tools accessible outside Neovim.
npm applications use `~/.local/bin` and a fixed per-command global prefix,
independent of nvm's version-specific global directories; pipx and Cargo are
user-global tools. Bootstrap installs and selects Node Iron through nvm, which
also supplies npm. Declarch uses the active `npm` on PATH. The macOS package
list also includes Homebrew `node`. Check npm engine requirements against the
active Node version when adding or updating tools.

Unix LSP setup uses executables on PATH, and broad Mason auto-installation is
disabled. macOS uses **only LemMinX** as a Mason exception because there is no
Homebrew formula; Mason's PATH is appended so native tools take precedence.
macOS `prosemd-lsp` uses its upstream Cargo package; its Apple Silicon
compatibility is unverified. Windows uses Mason to manage editor tooling.

[chezmoi reference]: https://www.chezmoi.io/reference/
[template]: htps://pkg.go.dev/text/template
[sprig]: http://masterminds.github.io/sprig/
[1]: https://1password.com/
