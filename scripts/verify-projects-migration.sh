#!/usr/bin/env bash
# Run on a deployed machine; replays the actual migration to verify no-op behavior.
shopt -s nullglob dotglob

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

chezmoi=$(command -v chezmoi) || fail 'chezmoi is required on the deployed machine'
[[ $("$chezmoi" execute-template '{{ .vaultsDir }}') == "$HOME/Projects" ]] || fail 'vaultsDir'
for path in "$HOME/source"/* "$HOME/source/repos"/*; do
    [[ $path == "$HOME/source/repos" ]] && continue
    [[ ! -d $path && ! -L $path ]] || fail "Unmigrated project: $path"
done

registry="${XDG_CONFIG_HOME:-$HOME/.config}/obsidian/obsidian.json"
[[ $(uname -s) != Darwin ]] || registry="$HOME/Library/Application Support/obsidian/obsidian.json"
if [[ -f $registry ]]; then
    paths=$(jq -r '.vaults[]?.path' "$registry") || fail 'Invalid Obsidian registry'
    while IFS= read -r path; do
        [[ -z $path ]] && continue
        [[ $path == "$HOME/Projects/"* && -d $path ]] || fail "Invalid vault: $path"
    done <<< "$paths"
fi

for path in "$HOME/.config/nvim/lua/config/lazy.lua" "$HOME/.config/nvim/lua/custom/utils.lua" "$HOME/.config/nvim/lua/plugins.lua" "$HOME/.config/tmux/tmux.conf"; do
    [[ -f $path ]] || fail "Missing deployed configuration: $path"
    content=$(< "$path")
    [[ $content == *Projects* && $content != *source/repos* ]] || fail "Stale deployed configuration: $path"
done

count=0
for path in "$HOME/Projects"/*; do
    [[ -d $path || -L $path ]] || continue
    ((count+=1))
    if [[ -e $path/.git ]]; then
        git -C "$path" status --porcelain=v1 >/dev/null || fail "Broken repository: $path"
        worktrees=$(git -C "$path" worktree list --porcelain) || fail "Worktrees: $path"
        [[ $worktrees != *"$HOME/source/"* ]] || fail "Stale worktree: $path"
        settings=$(git -C "$path" config --get-regexp 'remote\..*\.url|core\.worktree')
        [[ $settings != *"$HOME/source/"* ]] || fail "Stale Git configuration: $path"
    fi
done

snapshot() {
    for path in "$HOME/Projects"/*; do
        if [[ $(uname -s) == Darwin ]]; then
            stat -f '%i %m %N' "$path" || return 1
        else
            stat -c '%i %Y %n' "$path" || return 1
        fi
    done
    [[ ! -f $registry ]] || cksum "$registry"
}
before=$(snapshot) || fail 'Snapshot'
script=$(mktemp) || fail 'Temporary script'
trap 'rm -f "$script"' EXIT
source_dir=$("$chezmoi" source-path) || fail 'Source directory'
"$chezmoi" execute-template --file "$source_dir/.chezmoiscripts/run_onchange_before_00migrate-projects.sh.tmpl" --output "$script" || fail 'Render migration'
bash "$script" || fail 'Repeat migration'
"$chezmoi" execute-template --file "$source_dir/.chezmoiscripts/run_once_after_98clone-vaults.sh.tmpl.tmpl" --output "$script" || fail 'Render vault deployment'
bash "$script" || fail 'Repeat vault deployment'
after=$(snapshot) || fail 'Snapshot'
[[ $before == "$after" ]] || fail 'Repeated migration changed project inodes, mtimes or registry'
printf 'PASS: %s — %s project entries; Git/worktrees, vault paths and repeat-run no-op verified\n' "$(hostname)" "$count"
