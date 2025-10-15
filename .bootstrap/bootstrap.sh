#!/usr/bin/env bash

# Prepares the current system to deploy the dotfiles via chezmoi
# This is a pre-requisite, pure bash script. In particular, templating syntax
# is not available here

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
    [[ -z $3 ]] || exit "$3"
}

change-dir() {
    cd "$1" || {
        die f "Failed to change $1" 1
    }
}

bootstrap-linux() {
    # Determine Linux distro
    local ID_LIKE
    eval "$(grep -E '^ID_LIKE' /etc/os-release)"

    case "$ID_LIKE" in
        arch)
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
            UPDATE='paru -Syu'
            ;;
        *)
            die e "Unknown or not supported Linux derivative" 1
            ;;
    esac

    $UPDATE
    pipx --version >/dev/null 2>&1 || $INSTALL pipx
    mpm --version >/dev/null 2>&1 || pipx install meta-package-manager
}

bootstrap-darwin() {
    # Assume Apple silicon
    local brewPrefix='/opt/homebrew'

    # Install brew
    brew --version >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    INSTALL="${brewPrefix}/bin/brew install"

    mpm --version >/dev/null 2>&1 || $INSTALL meta-package-manager
}

OS="$(uname)"

case "${OS,}" in
    linux) bootstrap-linux ;;
    darwin) bootstrap-darwin ;;
    *)
        die e "$OS platform is not supported at this time." 1
        ;;
esac

# 1password
$INSTALL 1password
export OP_ACCOUNT=my.1password.com
eval "$(op signin)"

# chezmoi
$INSTALL chezmoi
chezmoi init --apply LeonardoMor
