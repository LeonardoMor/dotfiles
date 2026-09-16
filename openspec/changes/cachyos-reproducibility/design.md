## Context

See `proposal.md` for motivation. The repository is a Chezmoi source tree with a separate live checkout on Infinity. Its maintained package intent is split between two Metapac group files containing 486 unique Arch names, plus 5 npm and 1 pipx names. This change deliberately removes Alacritty and migrates the other 485 Arch names. Desktop provisioning overlaps with those declarations, and several package hooks also perform privileged service setup. Stable authored Hyprland policy is mixed intentionally with DMS-generated modules; other tracked files, notably Discord and pavucontrol state, are application-generated.

The implementation must be developed and tested on the VPS. Infinity remains read-only throughout this change. A minimal CachyOS installation, not the current installed-package snapshot, is the starting model.

## Goals / Non-Goals

**Goals:**

- Define one CachyOS machine-class path that completes package, Chezmoi, desktop, user-config, and service setup in one bootstrap invocation.
- Account for every maintained package declaration: preserve all retained names exactly and record Alacritty as the sole deliberate omission.
- Assign one authority to each package, stable configuration, generated artifact, and service action.
- Exercise real rendering and native validation in disposable fixtures without installing, removing, upgrading, pruning, or deploying.
- Keep rollback possible until the new authority has passed parity and fixture checks.

**Non-Goals:**

- Supporting, validating, or expanding macOS, Windows, generic Arch, or another Linux distribution.
- Reproducing Infinity's installed dependency closure, caches, histories, hardware inventory, credentials, or application-generated state.
- Building a package-reconciliation wrapper, ownership database, quarantine mechanism, graph parser, or service framework.
- Removing packages from Infinity or applying this branch there.
- Cleaning up package names merely because they appear dependency-like; only the explicitly approved Alacritty omission changes the maintained declarations.

## Decisions

### 1. Select the CachyOS machine class explicitly

CachyOS behavior is selected by `.osid == "linux-cachyos"`, not by hostname. Hostname checks remain only for genuinely machine-specific behavior such as Infinity's vault mount or hardware profile.

Alternative rejected: treat every Linux or Arch-like system as equivalent. That preserves the current accidental scope and makes fresh-install acceptance ambiguous.

### 2. Bootstrap owns completion

The bootstrap installs only prerequisites needed to obtain the repository and run its declared deployment, then calls `chezmoi init --apply` once. Declarch 0.8.2 is obtained through its official prebuilt-release installer because both current AUR PKGBUILDs are unusable; the bootstrap pins and verifies the installer, and the official installer verifies the selected release archive checksum. Successful return means the reviewed CachyOS deployment finished; README instructions will not ask for another `chezmoi apply`.

Scripts needed by the first apply remain self-contained or are ordered before their consumers. Later ordinary applies may reconcile content-sensitive changes, but they are not part of initial bootstrap completion. Required 1Password access fails closed with a direct diagnostic; secret-dependent features are omitted rather than populated with placeholders.

Alternative rejected: retain a two-command bootstrap/apply workflow. It exposes an implementation detail to the user and can conceal first-pass ordering defects.

Alternative rejected: preserve the broken AUR installation path or add a local PKGBUILD. The former is known not to complete and the latter would create repository-owned packaging around an upstream-provided binary installer.

### 3. Declarch becomes the sole package declaration authority

The root Declarch configuration imports two selected modules corresponding to the current `all` and `cachyos` groups. Package strings are quoted and compared programmatically:

- `paru`: 485 unique names, preserving 237 names in `all` and 248 retained names in `cachyos`, with zero overlap; `alacritty` is the one recorded omission from the 249-name source module.
- `npm`: 5 names, using Declarch's official npm backend.
- `pipx`: 1 name, using a minimal custom backend because the official registry provides pip rather than pipx.

The official `paru` backend owns both repository and AUR packages. The migration does not reclassify names among pacman/AUR backends. Metapac config, group symlinks, the Metapac package script, and the package-editing wrapper are removed only after exact source/result parity and fixture validation. The bootstrap prerequisite transition must not leave Metapac and Declarch as competing steady-state authorities.

Alternative rejected: derive modules from `pacman -Qqe`, split packages by current repository origin, or silently omit dependency-looking entries. Alacritty is the only approved change to maintained intent during migration.

### 4. Use native Declarch reconciliation honestly

The production workflow uses Declarch's lint and dry-run surfaces before sync. A real sync, prune, update, upgrade, cache clean, or hook execution requires explicit approval.

Declarch 0.8.2 prune operates on packages recorded in Declarch state; it does not promise removal of every manually installed explicit package absent from the modules. Therefore:

- the selected modules are the complete desired declaration for the enabled backends;
- initial sync adopts already-installed declared packages into Declarch state;
- approved `declarch sync prune` removes subsequently undeclared packages that remain represented in that state;
- `declarch info --list --scope unmanaged` reports other backend packages, but they are not claimed to be automatically pruned;
- no plain sync is run between deleting a declaration and an intended prune, because 0.8.2 may first drop the package from state;
- all imported module files must be present and parity-checked before any prune preview.

This is a deliberate limitation of the native tool, not a gap filled by a wrapper. If complete removal of arbitrary unmanaged packages becomes mandatory, Declarch must gain that behavior upstream or be replaced.

Alternative rejected: wrap Declarch and paru to emulate Metapac clean semantics. That would create the second package manager explicitly excluded by this change.

### 5. Separate package declarations from service configuration

Metapac `after_sync` shell hooks are not copied into Declarch modules. Packages declare packages; Chezmoi owns the smallest necessary system/user setup, and systemd owns activation state.

- Chezmoi-authored user units remain under `~/.config/systemd/user`.
- Package-supplied units are enabled by finite CachyOS setup scripts only where the intended enabled state is evidenced on Infinity.
- Group membership, udev, PAM, greetd, SSH, UFW, and fstab changes remain explicit privileged boundaries and are independently previewable where the native tool permits.
- Fixture execution substitutes harmless commands and paths; it never invokes real systemctl mutation, package mutation, firewall changes, or writes under `/etc`.

Alternative rejected: enable Declarch hooks and reproduce the current shell payloads. Declarch intentionally rejects embedded sudo/shell constructs, and package changes should not hide unrelated privileged mutations.

### 6. Package declarations, not DMS installer side effects, own packages

Declarch modules declare DMS, Hyprland, Ghostty, greetd, and their maintained companion packages. DMS-native commands may configure DMS or its greeter after packages exist, but may not act as a second package installer. The implementation will validate the installed DMS version's current CLI and generated Lua topology before changing setup.

Chezmoi continues to own `hyprland.lua` and `custom/*`; DMS continues to own `dms/*`, settings, output/layout, colors, and other generated state.

Alternative rejected: retain both the DMS dependency installer and Declarch declarations. Duplicate ownership makes fresh-install behavior and rollback unknowable.

### 7. Apply the location policy per tool, with deletion first

A source is centralized only when official documentation requires different native destinations across supported operating systems. Existing central Neovim and Vim templates remain valid. No non-CachyOS destination is added in this phase.

Alacritty configuration and its package declaration are deleted because they are unused. The package parity check treats `alacritty` as the sole explicit source-to-result omission rather than hiding the count difference.

Other central-template candidates are migrated only when official documentation proves that their native destination changes by operating system. Existing multiple destinations, aesthetics, deduplication, or possible future support are neither necessary nor sufficient reasons. Home-relative and Linux-only configurations stay in their corresponding home layout, and no non-CachyOS destination is added in this phase.

Alternative rejected: centralize by aesthetics or reorganize every tool during the CachyOS increment.

### 8. Applications own generated state

Chezmoi stops owning Discord `settings.json` and `pavucontrol.ini`. DMS output, Obsidian workspace/downloaded bundles, tmux plugin checkout, Neovim lock files, SSH known hosts, histories, caches, and 1Password-generated metadata remain excluded.

When source ownership is removed, the implementation distinguishes unmanaging a path from deleting live state. `.chezmoiremove` is used only when deletion of the rendered artifact is intentional; otherwise the application keeps or recreates it. Rollback preserves authored policy separately from generated payloads.

Alternative rejected: snapshot Infinity's current generated files. That would make Chezmoi compete with their runtime owners.

### 9. Verification uses rendered outputs and disposable fixtures

The implementation validates:

- exact package-name parity and uniqueness;
- Declarch KDL parsing, lint, backend loading, and dry-run plans;
- Chezmoi rendering with synthetic CachyOS data and no secret values;
- rendered shell syntax and native application parsers where available;
- first-bootstrap ordering with package/service/credential mutations replaced by fixture commands;
- absence of real package, service, firewall, credential, and deployment changes;
- `git diff --check`, complete diff review, and clean intended status.

Tests exercise the rendered files rather than reimplementing template logic in a parallel parser.

After those non-mutating checks pass, end-to-end convergence from a minimal CachyOS installation is verified in a disposable VM or equivalent machine that is created for acceptance and may be destroyed afterward. This is not fixture validation: running it installs packages and changes services inside that disposable machine, so it requires separate explicit approval. Infinity is never the acceptance target.

## Risks / Trade-offs

- **[Declarch cannot prune arbitrary unmanaged explicit packages]** → State the limitation, expose native unmanaged reporting, and do not add a wrapper.
- **[A missing imported module can make a prune preview unsafe]** → Require both module files, exactly 485 retained Arch names, and an explicit one-name Alacritty omission before any prune preview.
- **[A plain sync can forget a removed declaration before prune]** → Preview and execute the approved prune directly after the declaration change.
- **[The pipx backend adds local configuration]** → Keep it to the minimal documented list/install/remove mapping and test it with a mock binary.
- **[Removing DMS package-install side effects may omit undocumented dependencies]** → Preserve the 485 retained Arch declarations exactly; verify static behavior in non-mutating fixtures and real convergence only in the separately approved disposable acceptance machine.
- **[One-shot desktop state has drifted from current DMS behavior]** → Query the installed/current DMS CLI and validate generated destinations before replacing the stale setup.
- **[Secret rendering blocks unattended global Chezmoi checks]** → Use synthetic non-secret fixture data; reserve real secret-backed acceptance for an explicitly approved interactive run.
- **[End-to-end acceptance performs real package and service mutations]** → Run it only after explicit approval in a disposable minimal-CachyOS machine; never use Infinity.
- **[Unmanaging generated files can leave stale target files]** → Decide deletion versus leave-in-place per path and document rollback before source removal.
- **[Existing non-CachyOS files remain unverified]** → Make no compatibility claims and avoid touching them unless they compete with CachyOS authority.

## Migration Plan

1. Record immutable source inventories for both Metapac groups and their per-backend counts, then record `alacritty` as the one approved omission.
2. Add Declarch root config, two package modules, official paru/npm backend references, and the minimal pipx backend.
3. Validate exact package parity and all non-mutating Declarch checks in an isolated fixture.
4. Change bootstrap/package execution to install/use Declarch and complete one `chezmoi init --apply` flow in a fixture.
5. Move the five service-hook responsibilities to explicit native CachyOS setup, with harmless fixture substitutes.
6. Remove DMS package-install overlap while retaining app-native DMS configuration.
7. Remove Alacritty source and generated-state ownership identified in the proposal; apply explicit target-removal policy only where intended.
8. Remove Metapac config, group links, scripts, and wrapper after parity and fixture checks pass.
9. Update README to describe only the final one-command CachyOS workflow, preview commands, approval boundaries, and rollback.
10. Run independent review and full static/fixture validation.
11. With separate explicit approval, run end-to-end acceptance on a disposable minimal-CachyOS machine; otherwise record it as unverified in the checkpoint pull request.
12. Commit and open the checkpoint pull request without deploying to Infinity.

Rollback before deployment restores the Metapac sources and scripts and removes the new Declarch sources. This change stops before live adoption. Any future deployment or live rollback is separate approved scope and must begin with its own reviewed package and service preview.
