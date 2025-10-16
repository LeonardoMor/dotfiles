PACKAGESPREFIX={{ joinPath .chezmoi.sourceDir ".chezmoidata" }}

mapfile -t OTHERMANAGERS < <(
    mpm --output-format json managers |
        jq --argjson excluded {{ keys .packageManagers | toJson | squote }} \
            --raw-output 'keys - $excluded'
)

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
    cd "$1" || emit f "Failed to change $1" 1
}

{{- /*
vim: filetype=sh.gotmpl
*/}}
