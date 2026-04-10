#!/usr/bin/env bash

# Prepares the current system to deploy the dotfiles via chezmoi
# This is a pre-requisite, pure bash script. In particular, templating syntax
# is not available here

declare -l OS
FINAL_STAGE="$(mktemp)"

cleanup() {
    rm -f "$FINAL_STAGE"
}

trap cleanup EXIT

emit() {
    local rc=0
    case "$1" in
        i) printf '\nINFO: %s\n\n' "$2" >&2 ;;
        w)
            printf '\nWARNING: %s\n\n' "$2" >&2
            rc=1
            ;;
        e)
            printf '\nERROR: %s\n\n' "$2" >&2
            rc=1
            ;;
        f)
            printf '\nFATAL: %s\n\n' "$2" >&2
            rc=1
            ;;
        *) emit e "Invalid option or format" ;;
    esac
    [[ -z $3 ]] || exit "$3"
    return "$rc"
}

change-dir() {
    cd "$1" || emit f "Failed to change directory to $1" $?
}

is-installed() {
    command -v "$1" >/dev/null 2>&1 || emit w "$1 is not installed"
}

install-system-package-manager() {
    emit i "Installing $1"
    case "$1" in
        brew)
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            ;;
        paru)
            (
                change-dir "$HOME"
                sudo pacman --sync --sysupgrade
                sudo pacman --sync --needed base-devel
                git clone https://aur.archlinux.org/paru.git
                sudo mv paru /opt
                change-dir /opt/paru
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
    [[ ${1-} == "--" ]] && shift
    ARGS=("$@")
}

set-system-managers() {
    OS="$(uname)"
    case "$OS" in
        linux) OS="$(grep -E '^ID_LIKE' /etc/os-release | cut -d'=' -f2)" ;;
    esac

    case "$OS" in
        arch)
            set-INSTALL paru -- --sync --refresh --sysupgrade --needed --noconfirm
            METAPM=metapac
            ;;
        darwin)
            set-INSTALL -p "/opt/homebrew/bin" -- brew install
            METAPM=meta-package-manager
            ;;
        *) emit i "Unsupported OS" 1 ;;
    esac
}

_install() {
    "$INSTALL" "${ARGS[@]}" "$@"
}

# Entry point
set-system-managers
PREREQUISITES=(
    1password
    1password-cli
    chezmoi
    "$METAPM"
)

_install "${PREREQUISITES[@]}"

grep export <<<"$(op account add --signin </dev/tty)" >"$FINAL_STAGE"
echo "chezmoi init --apply --branch ${BRANCH:-master} LeonardoMor </dev/tty" >>"$FINAL_STAGE"
bash -x "$FINAL_STAGE"
