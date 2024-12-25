# My working environment

This will get most of what I need installed and configure some of it. Some stuff
will still require some manual interventions like
[setting up Nvidia drivers on Arch](https://github.com/korvahannu/arch-nvidia-drivers-installation-guide).

I'll automate and improve things as I go along.

To deploy the dotfiles on a new machine, run:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --verbose --apply LeonardoMor
```

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
dir that will produce a local `chezmoi.toml` once `chezmoi init` is run.

But some things on `chezmoi.toml` need to be variable. So you need some way to
indicate those instead of having them substituted by constants on
`chezmoi init`.

All the functions (and syntax) from
[text/template](https://pkg.go.dev/text/template), and the
[text template functions from `sprig`](http://masterminds.github.io/sprig/) are
available in `chezmoi`. So, one way to do this is to use the `print` function.
For example, this is the configuration for the merge tool on the template:

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

on the actual config file. Alternatively, you can use a lot of `"{{"` and
`"}}"`.

## Managing packages declaratively

There is a better way: NixOS. I'll not be going down that rabbit hole any time
soon. So here is my way to do it. Very likely there are better ways.

### Installing packages

`run_onchange` scripts are executed to install (and uninstall on macOS) packages
when a change is detected in the package file. The file is different on macOS
and Linux.

#### Linux

For Linux, I do it in exactly the way it's
[described in the user guide](https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/).

Theres an `install_cmd` that is defined in `chezmoi.toml` depending on the
version of Linux that's detected.

The `run_onchange` script tracks changes on the file
`.chezmoidata/packages.toml`. When there's a change, the list of packages is
formed from the toml list `packages.linux` and passed to the `install_cmd`.

Packages removed from the list are not uninstalled. To keep the list faithful to
the actual packages I use, uninstalled packages have to be manually removed from
the list.

It is worth noting, this packages file cannot be a template.

#### macOS

To tell the full story, on both Linux and macOS, some things have to be
installed before reading the source state. Arch Linux needs `paru` and macOS
needs Homebrew, both to install packages. And any OS needs `gnupg` to decrypt
secrets.

I can install and uninstall packages somewhat declaratively on macOS thanks to
[Brew-file](https://github.com/rcmdnk/homebrew-file/).

Brew-file is installed after the other pre-requisites. Then there's a wrap setup
on the `.profile`, along with auto-completion on `.bashrc`.

This wrap makes it so that `brew install` and `brew uninstall` update the
brewfile accordingly. And thanks to the following few lines in `.bashrc`, these
changes will be pushed to the dotfiles repo:

```sh
if {{ printf "%s/bin/brew" .brew_prefix }} --version >/dev/null 2>&1; then
	# Reference: https://stackoverflow.com/a/65980738/7830232
	eval {{ printf "$(%s/bin/brew shellenv)" .brew_prefix | quote }}

	# Set Homebrew-file
	if [ -f {{ printf "%s/etc/brew-wrap" .brew_prefix }} ]; then
		. {{ printf "%s/etc/brew-wrap" .brew_prefix }}

		_post_brewfile_update() {
			chezmoi git add .
			read -rp 'Commit message? '
			chezmoi git -- commit -m "$REPLY"
			chezmoi git push origin master
		}
	fi
fi
```

But the brewfile can also be edited manually. So for example, editing it with
the command:

```bash
chezmoi edit --apply "${XDG_CONFIG_HOME}/brewfile/Brewfile"
```

Will:

- Update and apply the updates to the home dir
- Commit and push the changes
- Will trigger the `.chezmoiscripts/darwin/run_onchange_install_packages.sh`

This script is very simply:

https://github.com/LeonardoMor/dotfiles/blob/master/.chezmoiscripts/darwin/run_onchange_install-packages.sh.tmpl#L1-L6

All thanks to Brew-file.

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
