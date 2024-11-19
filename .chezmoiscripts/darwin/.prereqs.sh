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

if /opt/homebrew/bin/brew --version >/dev/null 2>&1; then
	homebrew='/opt/homebrew/bin/brew'
elif /usr/local/bin/brew --version >/dev/null 2>&1; then
	homebrew='/usr/local/bin/brew'
elif /home/linuxbrew/.linuxbrew/bin/brew --version >/dev/null 2>&1; then
	homebrew='/home/linuxbrew/.linuxbrew/bin/brew'
fi

# Will manage brew packages with Homebrew-file
brew-file --version >/dev/null 2>&1 || {
	"$homebrew" install rcmdnk/file/brew-file
	brew-file set_local
}

{
	gpg --version >/dev/null 2>&1 || "$homebrew" install gnupg
} && "$($chezmoi source-path)/.chezmoiscripts/.import-gnupg-keys.sh"
