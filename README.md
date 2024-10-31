# My working environment

This will get most of what I need installed and configure some of it. Some stuff
will still require some manual interventions like
[setting up Nvidia drivers on Arch](https://github.com/korvahannu/arch-nvidia-drivers-installation-guide).

I'll automate and improve things as I go along.

## How it works

`chezmoi` [documentation](https://www.chezmoi.io/user-guide/) is pretty
excellent, I'll just put here some stuff that I find useful to keep in mind.

There is a source directory, `$(chezmoi source-path)` and a target directory,
which is the one that you want to manage and typically your `$HOME`.

`chezmoi` will produce a desired, target state based mainly on two things:

- The source files and directories located at the source dir
- The `${XDG_CONFIG_HOME}/chezmoi/chezmoi.toml` file

## `chezmoi.toml`, template of templates

You can use this file to manage machine to machine differences. The example
given in the docs is your git config. You might want to use your personal email
for your personal computer and your work email for your work computer.

Now it might be desirable to have a machine-specific `chezmoi.toml` files, so
you'd want to template it. You can add a file `.chezmoi.toml.tmpl` to the source
dir that will produce a `chezmoi.toml` on `chezmoi init`.

But some things on `chezmoi.toml` need to be variable. So you need some way to
indicate those instead of having them substituted by constants on
`chezmoi init`.

All the functions (and syntax) from Go templates are available (plus some more
stuff). So, one way to do this is to use the `print` function. For example, this
is the configuration for the merge tool on the template:

```toml
[merge]
    command = "nvim"
    args = ["-d", {{ print "{{.Destination}}" | quote }}, {{ print "{{.Source}}" | quote }}, {{ print "{{.Target}}" | quote }}]
```

Which produces:

```toml
[merge]
    command = "nvim"
    args = ["-d", "{{.Destination}}", "{{.Source}}", "{{.Target}}"]
```

on the actual config file.

## Managing packages declaratively

There is a better way: NixOS. I'll not be going down that rabbit hole any time
soon. So here is my way to do it. Very likely there are better ways.

### Installing packages

I have 3 lists of packages defined inside `.chezmoidata`. It looks like this:

```output
.chezmoidata
├── common_packages.toml
├── personal_packages.toml
└── work_packages.toml

1 directory, 3 files
```

Each of those is just an array belonging to the `packages` key.

The template `.chezmoiscripts/run_onchange_install-packages.sh.tmpl` produces a
script that will run after executing `chezmoi apply` whenever there was a change
on some package lists.

That script is a function of the packages lists, the hostname and the OS. So the
correct packages are installed correctly.

So to install a package (while keeping track of it), I simply add it to the
correct list.

Notice however that deleting a package from the list will trigger a run of the
installation script, but that will not uninstall the package.

### Uninstalling packages

Since `chezmoi diff` only reports diffs on managed files, we'll have to rely on
git to detect packages that have been removed from any of the lists.

To do so, this is my chezmoi configuration for git:

```toml
[git]
    autoPush = true
    commitMessageTemplate = "{{ promptString \"Commit message\" }}"
```

> [!WARNING] If any secrets are to be managed, add them with
> `chezmoi add --encrypt`.

chezmoi has hooks that we can use. For this usecase, I'm simply using the
`apply.post` hook to run a command. Specifically:

```toml
[hooks.apply.post]
    command = "{{.chezmoi.homeDir}}/bin/uninstall-removed.sh"
```

The `uninstall-removed.sh` comes with a template that will use the correct
command to uninstall the packages that were removed from the relevant lists.

## Encrypt secrets

I prefer asymmetric encryption with gpg. So I created a gpg key pair and pass my
email as the recipient to chezmoi. Secrets will be encrypted with my public key
and decrypted with my private key on the local machine. You have to responsible
for that one key.

The config is to simply add the following at the top of `.chezmoi.toml`:

```toml
encryption = "gpg"
[gpg]
    recipient = "leomc145@gmail.com"
```
