## Purpose

Defines the authoritative CachyOS package declaration, its exact migration accounting, safe preview behavior, and the limits of native reconciliation.

## ADDED Requirements

### Requirement: Exact migration accounting
The migration SHALL account for every current source declaration: the Declarch result SHALL contain 488 unique Arch package names, 6 npm package names, and 1 pipx package name, while recording `alacritty` as the sole deliberate omission from the 489-name Arch source.

#### Scenario: Package declarations are compared
- **WHEN** source Metapac data and resulting Declarch modules are compared programmatically
- **THEN** all 488 retained Arch names match exactly
- **AND** all 6 npm and 1 pipx names match exactly
- **AND** the only source name absent from the result is `alacritty`

#### Scenario: Unexpected package difference exists
- **WHEN** comparison finds a renamed, additional, duplicated, or missing package other than `alacritty`
- **THEN** migration validation fails
- **AND** Metapac authority is retained

### Requirement: CachyOS module selection
The CachyOS package authority SHALL select the shared package module and CachyOS package module together, containing 237 and 248 retained Arch names respectively with no overlap.

#### Scenario: Complete module set loads
- **WHEN** package configuration is resolved for the CachyOS machine class
- **THEN** both selected modules load
- **AND** their Arch union contains exactly 488 unique names

#### Scenario: Required module is absent
- **WHEN** either selected module is missing or cannot be loaded
- **THEN** sync and prune validation fails before package mutation

### Requirement: One package authority
After verified migration, Declarch modules SHALL be the sole reusable package declaration for the CachyOS machine class; Metapac declarations and execution paths SHALL no longer be active authorities.

#### Scenario: Migration acceptance passes
- **WHEN** exact parity, configuration validation, and fixture checks succeed
- **THEN** active package operations resolve from Declarch modules
- **AND** no active Metapac config, group link, package script, or package-editing wrapper remains

#### Scenario: Migration acceptance fails
- **WHEN** a required migration check fails
- **THEN** the existing Metapac authority remains recoverable
- **AND** the system does not expose competing active authorities

### Requirement: Desired declarations are not installed-state snapshots
The package declaration SHALL derive from the maintained source lists and approved omissions, not from Infinity's current installed package inventory or dependency closure.

#### Scenario: Infinity has extra explicit packages
- **WHEN** an explicitly installed package is absent from the maintained source declarations
- **THEN** it is not added to the Declarch modules solely because it is installed on Infinity

### Requirement: Safe package preview
Package linting, configuration validation, and dry-run planning SHALL perform no real installation, removal, upgrade, pruning, cache cleaning, or hook execution.

#### Scenario: Non-mutating validation runs
- **WHEN** package validation executes in a fixture
- **THEN** the real package database and Declarch state remain unchanged
- **AND** no package-manager mutation command reaches the host

#### Scenario: Destructive reconciliation is requested
- **WHEN** a real sync, prune, update, upgrade, cache clean, or hook-enabled operation is proposed
- **THEN** the operation remains blocked pending explicit approval
- **AND** its native preview is reviewed separately first

### Requirement: Native sync checkpoints package declarations
A hook-enabled Declarch sync SHALL use Declarch's native lifecycle to record the rendered `all` and `cachyos` modules with Chezmoi and create one module-only Git commit without pushing or disturbing unrelated staged changes.

#### Scenario: Approved hook-enabled sync changes a module
- **WHEN** an approved `declarch sync --hooks` succeeds after either rendered module changes
- **THEN** the on-success hook records the two modules in Chezmoi source and commits only those source paths
- **AND** pushing remains an explicit separate action

#### Scenario: Sync has no declaration change
- **WHEN** hook-enabled sync succeeds without changing either module
- **THEN** the hook exits successfully without creating an empty commit

#### Scenario: Chezmoi automatic Git actions are enabled
- **WHEN** the user's Chezmoi configuration enables automatic add, commit, or push
- **THEN** the module-recording command disables those automatic actions in an in-memory configuration copy while retaining the active template data needed by `.chezmoiignore` and `.chezmoiremove`
- **AND** the user's normal Chezmoi configuration remains unchanged
- **AND** only the two module source paths may be committed, unrelated staged changes survive, and no push occurs

#### Scenario: Preview or hooks-disabled sync runs
- **WHEN** a dry run or a sync without `--hooks` runs
- **THEN** no declaration commit hook executes

### Requirement: Native prune behavior is represented honestly
The workflow SHALL use native Declarch prune behavior without a reconciliation wrapper and SHALL NOT claim that it removes arbitrary unmanaged explicit packages.

#### Scenario: Previously tracked declaration is removed
- **WHEN** an approved prune is previewed immediately after deleting a package represented in Declarch state
- **THEN** the package appears as a native prune candidate

#### Scenario: Unmanaged package is present
- **WHEN** a backend package is not represented in Declarch state or selected declarations
- **THEN** it is reportable as unmanaged
- **AND** the workflow does not claim native prune will remove it

#### Scenario: Declaration removal awaits prune
- **WHEN** a declaration has been deleted and removal is intended
- **THEN** no intervening plain sync is run before the prune preview and approved prune

### Requirement: Package backends preserve package classes
The retained Arch names SHALL use one backend capable of repository and AUR packages, npm names SHALL use the npm package class, and the pipx name SHALL remain a pipx-managed application.

#### Scenario: Backend configuration is inspected
- **WHEN** the selected package configuration is resolved
- **THEN** no Arch name is silently reclassified or renamed
- **AND** npm and pipx declarations remain in their original package classes

### Requirement: Native ownership without parallel frameworks
The implementation SHALL NOT add a package-reconciliation wrapper, package ownership database, quarantine mechanism, graph parser, evidence framework, service framework, or other parallel orchestration around native Declarch, Chezmoi, package-manager, systemd, or application behavior.

#### Scenario: Implementation diff is reviewed
- **WHEN** changed executable and configuration paths are inspected before the checkpoint
- **THEN** each added mechanism is a direct native configuration or the smallest required command mapping
- **AND** no prohibited wrapper, database, parser, quarantine, evidence, or service framework is present
