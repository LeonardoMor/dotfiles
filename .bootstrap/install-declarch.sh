#!/usr/bin/env bash

# v0.8.2 needs a state-dir fallback on macOS; Linux uses the AUR binary package.
SCRIPT_DIR=$(cd -- "${BASH_SOURCE[0]%/*}" && pwd) || exit 1
OS=$(uname -s) || exit 1
case $OS in
    Linux)
        paru -S --needed declarch-bin || exit 1
        ;;
    Darwin)
        BREW=$(command -v brew) || {
            printf '%s\n' 'Homebrew must be installed and on PATH first.' >&2
            exit 1
        }
        "$BREW" install rust git || exit 1
        BUILD_DIR=$(mktemp -d) || exit 1
        trap 'rm -rf -- "$BUILD_DIR"' EXIT
        git clone --quiet --depth 1 --branch v0.8.2 \
            https://github.com/nixval/declarch.git "$BUILD_DIR/declarch" || exit 1
        git -C "$BUILD_DIR/declarch" apply "$SCRIPT_DIR/declarch-state-dir.patch" || exit 1
        cargo install --locked --path "$BUILD_DIR/declarch" --bin declarch \
            --root "$HOME/.local" || exit 1
        "$HOME/.local/bin/declarch" --version || exit 1
        ;;
    *)
        printf 'Unsupported OS: %s\n' "$OS" >&2
        exit 1
        ;;
esac
