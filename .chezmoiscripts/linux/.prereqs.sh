#!/usr/bin/env bash

set -e

NAME="$(basename "$0")"

help() {
	cat <<EOF
Handles pre requisites on Linux systems.

usage: $NAME [-h]

options:
	-h    Show this help message and exit
EOF
}

while getopts "h" option; do
	case $option in
		h)
			help
			exit
			;;
		*)
			help >&2
			exit 1
			;;
	esac
done

change_dir() {
	cd "$1" || {
		printf 'Failed to change dir to %s\n' "$1" >&2
		exit 1
	}
}

# Main logic goes here
OPERATING_SYSTEM="$(awk -F= '/^ID=/{print $2}' /etc/*-release)"
case "$OPERATING_SYSTEM" in
	arch)
		paru --version >/dev/null 2>&1 || (
			change_dir "$HOME"
			sudo pacman --sync --needed base-devel
			git clone https://aur.archlinux.org/paru.git
			sudo mv paru /opt
			change_dir /opt/paru
			makepkg -si
		)
		install_cmd='paru --noconfirm --sync --needed'
		;;
	*)
		printf 'Unsupported operating system: %s\n' "$OPERATING_SYSTEM" >&2
		exit 1
		;;
esac

{
	gpg --version >/dev/null 2>&1 || "$install_cmd" gnupg
} && "$(chezmoi source-path)/.chezmoiscripts/.import-gnupg-keys.sh"
