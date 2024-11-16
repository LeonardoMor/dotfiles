#!/bin/bash

set -e

brew --version >/dev/null 2>&1 || {
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh

	if /opt/homebrew/bin/brew --version >/dev/null 2>&1; then
		homebrew='/opt/homebrew/bin/brew'
	elif /usr/local/bin/brew --version >/dev/null 2>&1; then
		homebrew='/usr/local/bin/brew'
	elif /home/linuxbrew/.linuxbrew/bin/brew --version >/dev/null 2>&1; then
		homebrew='/home/linuxbrew/.linuxbrew/bin/brew'
	fi

	# Reference: https://stackoverflow.com/a/76720643/7830232
	echo "eval \$($homebrew shellenv)" >>~/.profile
}

{
	gpg --version >/dev/null 2>&1 || "$homebrew" install gnupg
} && "$(chezmoi source-path)/.chezmoiscripts/.import-gnupg-keys.sh"
