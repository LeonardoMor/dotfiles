#!/usr/bin/env bash

DECLARCH_INSTALLER_SHA256=bce51b98ae7af63b5fa58669ae8f6b9d601e14114ec8bb002de2b9523c1c288a
DECLARCH_VERSION=0.8.2
INSTALLER=

emit() {
    local level=${1:-} message=${2:-} exit_code=${3:-}

    case $level in
        i) printf 'INFO: %s\n' "$message" >&2 ;;
        w) printf 'WARNING: %s\n' "$message" >&2 ;;
        e) printf 'ERROR: %s\n' "$message" >&2 ;;
        f) printf 'FATAL: %s\n' "$message" >&2 ;;
        *)
            printf 'ERROR: Invalid log level: %s\n' "$level" >&2
            return 2
            ;;
    esac

    [[ -z $exit_code ]] || exit "$exit_code"
}

change-dir() {
    cd "$1" || emit f "Failed to change directory to $1" 1
}

is-installed() {
    command -v "$1" >/dev/null 2>&1
}

cleanup() {
    [[ -z $INSTALLER ]] || rm -f "$INSTALLER" || emit w "Failed to remove $INSTALLER"
}

trap cleanup EXIT INT TERM HUP QUIT

[[ -r /etc/os-release ]] || emit f 'Cannot read /etc/os-release' 1
source /etc/os-release || emit f 'Failed to read /etc/os-release' 1
[[ ${ID:-} == cachyos ]] || emit f "Unsupported OS: ${ID:-unknown}; CachyOS is required" 1

if ! is-installed paru; then
    emit i 'Installing paru from the CachyOS repository'
    sudo pacman --sync --refresh --sysupgrade --needed --noconfirm paru || emit f 'Failed to install paru' 1
fi

emit i 'Installing bootstrap prerequisites'
paru --sync --refresh --sysupgrade --needed --noconfirm \
    1password \
    1password-cli \
    chezmoi \
    curl \
    nvm \
    python-pipx || emit f 'Failed to install bootstrap prerequisites' 1

if ! is-installed declarch; then
    emit i "Installing Declarch $DECLARCH_VERSION with its official release installer"
    INSTALLER=$(mktemp) || emit f 'Failed to create a temporary installer file' 1
    curl -fsSL "https://raw.githubusercontent.com/nixval/declarch/v$DECLARCH_VERSION/install.sh" -o "$INSTALLER" || \
        emit f 'Failed to download the Declarch installer' 1
    printf '%s  %s\n' "$DECLARCH_INSTALLER_SHA256" "$INSTALLER" | sha256sum -c - || \
        emit f 'Declarch installer checksum verification failed' 1
    DECLARCH_VERSION=$DECLARCH_VERSION bash "$INSTALLER" || emit f 'Failed to install Declarch' 1
    hash -r || emit f 'Failed to refresh the command lookup cache' 1
fi

for c in op chezmoi declarch; do
    is-installed "$c" || emit f "$c is unavailable after prerequisite installation" 1
done

if ! op whoami >/dev/null 2>&1; then
    emit i 'Authenticating 1Password'
    if ! OP_SESSION=$(op signin --raw </dev/tty); then
        emit i 'Adding a 1Password account'
        OP_SESSION=$(op account add --signin --raw </dev/tty) || emit f '1Password sign-in failed' 1
    fi
    [[ -n $OP_SESSION ]] || emit f '1Password returned an empty session token' 1
    export OP_SESSION
    op whoami >/dev/null 2>&1 || emit f '1Password sign-in failed' 1
fi

chezmoi init --apply --branch "${BRANCH:-master}" LeonardoMor </dev/tty || emit f 'Chezmoi deployment failed' 1
