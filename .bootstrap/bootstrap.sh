#!/usr/bin/env bash

# Prepares the current system to deploy the dotfiles via chezmoi
# This is a pre-requisite, pure bash script. In particular, templating syntax
# is not available here

emit() {
    case "$1" in
        i) printf 'INFO: %s\n' "$2" >&2 ;;
        e) printf 'ERROR: %s\n' "$2" >&2 ;;
        w) printf 'WARNING: %s\n' "$2" >&2 ;;
        f) printf 'FATAL: %s\n' "$2" >&2 ;;
        *) emit e "Invalid option or format" ;;
    esac
    [[ -z $3 ]] || exit "$3"
}

change-dir() {
    cd "$1" || emit f "Failed to change directory to $1" $?
}

is-installed() {
    command -v "$1" || emit w "$1 not is installed"
}

install-system-package-manager() {
    emit -i "Installing $1"
    case "$1" in
        brew)
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            ;;
        paru)
            (
                change_dir "$HOME"
                sudo pacman --sync --sysupgrade
                sudo pacman --sync --needed base-devel
                git clone https://aur.archlinux.org/paru.git
                sudo mv paru /opt
                change_dir /opt/paru
                makepkg -si
            )
            ;;
        *) emit e "$1 package manager not supported" 1 ;;
    esac
}

set-INSTALL() {
    local opt OPTIND OPTARG
    while getopts 'p:' opt; do
        case "$opt" in
            p)
                INSTALL="${OPTARG}/"
                ;;
            *)
                emit i "set-INSTALL: wrong option"
                ;;
        esac
    done
    shift $((OPTIND - 1))

    is-installed "$1" || install-system-package-manager "$1"
    INSTALL+="$1"
    shift
    ARGS=("$@")
}

set-system-package-manager() {
    local uname_out
    uname_out="$(uname)"
    case "$uname_out" in
        Darwin) OS="${uname_out,,}" ;;
        Linux) OS="$(grep -E '^ID_LIKE' /etc/os-release | cut -d'=' -f2)" OS="${OS,,}" ;;
        *) emit i "Unsupported OS" 1 ;;
    esac

    case "$OS" in
        arch) set-INSTALL paru -- --sync --refresh --sysupgrade --needed --noconfirm ;;
        darwin) set-INSTALL -p "/opt/homebrew/bin" -- brew install ;;
    esac
}

_install() {
    "$INSTALL" "${ARGS[@]}" "$@"
}

PREREQUISITES=(
    1password
    1password-cli
    chezmoi
    pipx
)

install-meta-pm() {
    # The selected one is mpm for now
    is-installed mpm || _install mpm || {
        is-installed pipx || _install pipx
        pipx install mpm
    }
}

# Entry point
set-system-package-manager
_install "${PREREQUISITES[@]}"
install-meta-pm

export OP_ACCOUNT=my.1password.com
eval "$(op signin)"

chezmoi init --apply LeonardoMor
