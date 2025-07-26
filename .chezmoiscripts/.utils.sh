#!/usr/bin/env bash

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
