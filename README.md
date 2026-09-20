# CachyOS dotfiles

This repository reproduces the intended Infinity workstation experience from a minimal CachyOS installation with no desktop environment.

## Bootstrap

1Password must be available for interactive authentication. On a fresh machine, bootstrap prompts to add and sign in to the account before deployment. Required secret-backed configuration fails closed when authentication is unavailable.

```bash
curl -fsSL https://github.com/LeonardoMor/dotfiles/raw/refs/heads/master/.bootstrap/bootstrap.sh | bash
```

The bootstrap accepts only CachyOS, installs its minimal prerequisites, and performs exactly one `chezmoi init --apply`. It installs pinned Declarch 0.8.2 through Declarch's official release installer after verifying the installer SHA-256; that installer verifies the release archive checksum. A second apply is not part of the bootstrap workflow.

## Package state

The complete CachyOS package declaration is split by reuse scope:

- `home/dot_config/declarch/exact_modules/all.kdl`
- `home/dot_config/declarch/exact_modules/cachyos.kdl`

Paru owns Arch/AUR packages, npm owns global Node packages, and pipx owns isolated Python applications. Declarch configuration is rendered to `~/.config/declarch`. `dms-shell`, `greetd`, and `greetd-dms-greeter-git` are declared in `all.kdl`; the desktop setup does not install them a second time.

Before changing the live package state:

```bash
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
for module in all cachyos; do
    test -r "$config_home/declarch/modules/$module.kdl" || {
        printf 'Missing Declarch module: %s\n' "$module" >&2
        exit 1
    }
done
declarch lint --mode validate
declarch --dry-run sync
declarch info --list --scope unmanaged
```

Edit a rendered module with `declarch edit all` or `declarch edit cachyos`, then review the native Declarch plan. A successful `declarch sync --hooks` records the two modules with Chezmoi and creates a module-only Git commit; pushing remains explicit. Real sync, update, upgrade, cache-clean, or prune operations require explicit approval.

Declarch prune removes packages that were represented in its state and later undeclared. It does not remove arbitrary unmanaged packages. After deleting a tracked declaration, preview and execute prune directly:

```bash
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
for module in all cachyos; do
    test -r "$config_home/declarch/modules/$module.kdl" || {
        printf 'Missing Declarch module: %s\n' "$module" >&2
        exit 1
    }
done
declarch lint --mode validate
declarch --dry-run sync --hooks prune
# after explicit review and approval
declarch sync --hooks prune
```

Do not run a plain sync between declaration removal and the intended prune; Declarch 0.8.2 may first drop the removed package from its state.

## Configuration ownership

Chezmoi owns stable authored configuration: shell setup, terminal/editor policy, Hyprland root and personal overlays, keybindings, service intent, fonts, and themes.

Applications own generated or mutable state, including Discord settings, pavucontrol UI state, DMS-generated modules/settings/output data, Obsidian workspaces and downloaded bundles, plugin checkouts, lock files, histories, caches, and SSH known hosts.

DMS owns its generated Hyprland modules. Chezmoi owns `hyprland.lua` and `custom/*` and does not duplicate DMS output.

## Service state

CachyOS setup uses package-provided units where available and Chezmoi only for authored units and finite activation commands. The base CachyOS installer owns NetworkManager activation. Chezmoi owns the remaining selected workstation state: Kanata's `uinput` group and udev rule, required device-group membership, PAM, greetd, SSH, firewall, printing, Bluetooth, virtualization, and user-service activation.

Infinity-specific mounts, symlinks, and hardware behavior remain hostname-gated. Infinity is a read-only reference during development and is never an acceptance target.

## Verification and rollback

Non-mutating verification uses synthetic Chezmoi data, rendered outputs, harmless package/service substitutes, native parsers, and Declarch dry runs. Real package, service, firewall, credential, or deployment changes require separate approval and a disposable minimal-CachyOS acceptance machine.

Rollback starts with Git: restore the prior reviewed source, render the affected targets, and inspect the resulting Chezmoi and Declarch previews. Do not perform live package or service rollback without separately reviewing the destructive plan.
