#!/usr/bin/env bash

set -euo pipefail

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

os_release=${DOTFILES_OS_RELEASE:-/etc/os-release}
[[ -r $os_release ]] || emit f "Cannot read $os_release" 1
os_id=$(awk -F= '$1 == "ID" { value=$2; gsub(/^"|"$/, "", value); print value; exit }' "$os_release")
[[ $os_id == cachyos ]] || emit f "Unsupported OS: ${os_id:-unknown}; CachyOS is required" 1

if ! command -v paru >/dev/null 2>&1; then
    emit i 'Installing paru from the CachyOS repository'
    sudo pacman --sync --refresh --sysupgrade --needed --noconfirm paru
fi

emit i 'Installing bootstrap prerequisites'
paru --sync --refresh --sysupgrade --needed --noconfirm \
    1password \
    1password-cli \
    chezmoi \
    curl \
    nvm \
    python-pipx

if ! command -v declarch >/dev/null 2>&1; then
    emit i 'Installing Declarch 0.8.2 with its official release installer'
    (
        installer=$(mktemp)
        trap 'rm -f "$installer"' EXIT
        curl -fsSL https://raw.githubusercontent.com/nixval/declarch/v0.8.2/install.sh -o "$installer"
        printf '%s  %s\n' \
            bce51b98ae7af63b5fa58669ae8f6b9d601e14114ec8bb002de2b9523c1c288a \
            "$installer" | sha256sum -c -
        DECLARCH_VERSION=0.8.2 bash "$installer"
    )
    hash -r
fi

for command in op chezmoi declarch; do
    command -v "$command" >/dev/null 2>&1 || emit f "$command is unavailable after prerequisite installation" 1
done

if ! op whoami >/dev/null 2>&1; then
    emit i 'Authenticating 1Password'
    if ! signin=$(op signin </dev/tty); then
        emit i 'Adding a 1Password account'
        signin=$(op account add --signin </dev/tty) || emit f '1Password sign-in failed' 1
    fi
    eval "$signin"
    unset signin
    op whoami >/dev/null 2>&1 || emit f '1Password sign-in failed' 1
fi

chezmoi init --apply --branch "${BRANCH:-master}" LeonardoMor </dev/tty
