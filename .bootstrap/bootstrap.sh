#!/usr/bin/env bash

# Prepares the current system to deploy the dotfiles via chezmoi
# This is a pre-requisite, pure bash script. In particular, templating syntax
# is not available here

set -o errexit

die() {
    case "$1" in
        i)
            printf 'INFO: %s\n' "$2" >&2
            ;;
        e)
            printf 'ERROR: %s\n' "$2" >&2
            ;;
        w)
            printf 'WARNING: %s\n' "$2" >&2
            ;;
        f)
            printf 'FATAL: %s\n' "$2" >&2
            ;;
        *)
            die e "Invalid option or format"
            ;;
    esac
}

change_dir() {
    cd "$1" || {
        die e "Failed to change $1"
        exit 1
    }
}

bootstrap_linux() {
    # TODO: add logic to detect whether the distro is an Arch derivative.
    # Detect other derivatives as you go along.
    # DISTRO="$(awk -F'=' '/^NAME/{ print $2 }' /etc/*-release | xargs)"
    # Assuming Arch derivative for now

    # Install paru
    paru --version >/dev/null 2>&1 || (
        change_dir "$HOME"
        sudo pacman --sync --sysupgrade
        sudo pacman --sync --needed base-devel
        git clone https://aur.archlinux.org/paru.git
        sudo mv paru /opt
        change_dir /opt/paru
        makepkg -si
    )
    INSTALL='paru --noconfirm --sync --needed'
}

bootstrap_darwin() {
    # Assume Apple silicon
    local brew_prefix='/opt/homebrew'
    local Brewfile="${XDG_CONFIG_HOME:-~/.config}/brewfile/Brewfile"

    # Install brew
    brew --version >/dev/null 2>&1 || {
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    }
    INSTALL="${brew_prefix}/bin/brew install"

    # Will manage brew packages with Homebrew-file
    brew-file --version >/dev/null 2>&1 || {
        $INSTALL rcmdnk/file/brew-file
    }
    if [[ -L $Brewfile ]] && [[ ! -e $Brewfile ]]; then
        rm -f "$Brewfile"
        touch "$Brewfile"
    fi
    "${brew_prefix}/bin/brew-file" set_local
    INSTALL="${brew_prefix}/bin/brew-file install"
}

OS="$(uname)"

case "${OS,}" in
    linux) bootstrap_linux ;;
    darwin) bootstrap_darwin ;;
    *)
        die e "$OS platform is not supported at this time."
        exit
        ;;
esac

# 1password
$INSTALL 1password
export OP_ACCOUNT=my.1password.com
eval "$(op signin)"

# chezmoi
$INSTALL chezmoi
chezmoi init --apply LeonardoMor
