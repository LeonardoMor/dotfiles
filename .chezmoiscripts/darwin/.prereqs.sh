#!/bin/bash

set -e

if chezmoi --version >/dev/null 2>&1; then
	chezmoi=chezmoi
else
	chezmoi=~/bin/chezmoi
fi

brew --version >/dev/null 2>&1 || {
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	$chezmoi init
}

homebrew='/opt/homebrew/bin/brew'

# Will manage brew packages with Homebrew-file
brew-file --version >/dev/null 2>&1 || {
	"$homebrew" install rcmdnk/file/brew-file
	brew-file set_local
}

# {
# 	gpg --version >/dev/null 2>&1 || "$homebrew" install gnupg
# } && "$($chezmoi source-path)/.chezmoiscripts/.import-gnupg-keys.sh"

"$homebrew" list 1password >/dev/null 2>&1 || "$homebrew" install 1password
op --version >/dev/null 2>&1 || "$homebrew" install 1password-cli

[[ -d /Applications/Alt-C.app ]] || {
	curl --location --output ~/Downloads/alt-c.pkg https://altcopy.net/setup.pkg
	sudo installer -pkg ~/Downloads/alt-c.pkg -target /
}
