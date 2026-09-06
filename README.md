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

Here is how things are expected to work. macOS goes first because (at least for
this) it is an ideal situation.

## macOS

The bootstrap installs Homebrew and applies Chezmoi. Formula and cask desired
state live in `.chezmoidata/brew.toml` and `.chezmoidata/cask.toml`.

## Manage packages declaratively with `metapac`

See [metapac](https://github.com/ripytide/metapac).

`metapac` config is tracked with `chezmoi`. Later, if I have to, I'll track it
as template to also use this system on Windows.

`metapac` groups are tracked with `chezmoi` as externally modifiable files.

### Linux

CachyOS for now, but with this system it'll be just as easy to deploy these
dotfiles on other distros.

The workflow is as follows:

#### Installing packages

1. Run

```bash
metapac add --backend arch --group GROUP --package PACKAGE
```

This will add the package to the `GROUP` group.

2. Run

```bash
chezmoi apply --verbose
```

There's a script in `.chezmoiscripts/linux` that will detect the change and run
the `metapac sync`.

#### Uninstalling packages

First, run

```bash
metapac remove --backend arch --package PACKAGE
```

The second step is the same.

Once you're happy with the changes, add and commit them:

```bash
chezmoi git add .
chezmoi git commit
```

### Windows

Once setup, things should work in the same way as on Linux.

[chezmoi reference]: https://www.chezmoi.io/reference/
[template]: htps://pkg.go.dev/text/template
[sprig]: http://masterminds.github.io/sprig/
[1]: https://1password.com/
