#!/usr/bin/env bash

set -e

NAME="$(basename "$0")"

help() {
	cat <<EOF
This does things needed to initialize the computing environment.

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

install_paru() {
	if paru --version >/dev/null 2>&1; then
		return
	fi
	change_dir "$HOME"
	sudo pacman -S --needed base-devel
	git clone https://aur.archlinux.org/paru.git
	sudo mv paru /opt
	change_dir /opt/paru
	makepkg -si
}

# Main logic goes here
OPERATING_SYSTEM="$(awk -F= '/^ID=/{print $2}' /etc/*-release)"
case "$OPERATING_SYSTEM" in
	arch)
		install_paru
		;;
	*)
		printf 'Unsupported operating system: %s\n' "$OPERATING_SYSTEM"
		exit 1
		;;
esac
