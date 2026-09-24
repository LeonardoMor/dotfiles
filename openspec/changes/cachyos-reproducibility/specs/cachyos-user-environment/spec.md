## Purpose

Defines the stable authored user experience for the CachyOS workstation while preserving application ownership of generated and mutable runtime state.

## ADDED Requirements

### Requirement: Stable workstation configuration
Chezmoi SHALL own the stable authored shell, terminal, editor, desktop, theme, keybinding, and application preferences required for the intended CachyOS user experience.

#### Scenario: CachyOS source is rendered
- **WHEN** Chezmoi renders with CachyOS machine-class data
- **THEN** stable authored files resolve to their documented CachyOS destinations
- **AND** hardware-specific values are included only when selected by machine data

### Requirement: Configuration source placement follows documented destinations
A configuration source SHALL be centralized only when the tool's official documentation shows that its native destination changes by operating system; home-relative and Linux-only configurations SHALL remain in their corresponding home layout.

#### Scenario: Documented destinations differ by operating system
- **WHEN** one authored configuration targets officially documented OS-specific native destinations
- **THEN** one central source template may render through thin native-destination files

#### Scenario: Documented destination does not differ
- **WHEN** a tool uses the same home-relative or XDG destination on its supported systems
- **THEN** its source remains in the corresponding home-directory layout
- **AND** aesthetics, deduplication, or hypothetical support do not cause centralization

### Requirement: Alacritty is absent from desired state
The CachyOS desired state SHALL contain neither an Alacritty configuration nor an Alacritty package declaration.

#### Scenario: Source and package modules are inspected
- **WHEN** the resulting CachyOS source and package declarations are checked
- **THEN** no managed Alacritty configuration exists
- **AND** `alacritty` is absent from selected package modules

### Requirement: Generated application state remains application-owned
Chezmoi SHALL NOT own Discord runtime settings, pavucontrol UI state, DMS-generated settings/modules/output/layout/colors, Obsidian workspace or downloaded bundles, tmux plugin checkout, Neovim lock files, SSH known hosts, histories, caches, or 1Password-generated metadata.

#### Scenario: Generated-state inventory is checked
- **WHEN** Chezmoi source destinations are enumerated
- **THEN** the listed generated paths are absent or explicitly ignored
- **AND** no generated snapshot is used as desired state

#### Scenario: Generated ownership is removed
- **WHEN** Discord settings or pavucontrol state is removed from Chezmoi source
- **THEN** the migration explicitly chooses whether to leave or delete the existing destination
- **AND** source deletion alone is not treated as proof of destination removal

### Requirement: Hyprland and DMS ownership remains split
Chezmoi SHALL own the authored Hyprland root and personal overlays, while DMS SHALL own its generated modules, settings, layout, colors, and output state.

#### Scenario: Assembled Hyprland configuration is validated
- **WHEN** the CachyOS Hyprland configuration is assembled in a fixture
- **THEN** the Chezmoi-authored root and overlays load the expected DMS-owned modules
- **AND** Chezmoi does not provide competing copies of those generated modules

### Requirement: Secrets are not source state
Secret and credential values SHALL NOT be committed, copied from Infinity, emitted in validation logs, or replaced with plausible fixture values.

#### Scenario: Secret-bearing template is validated
- **WHEN** a template requires secret-backed data during non-interactive validation
- **THEN** synthetic non-secret structure or an explicit omission is used
- **AND** no real secret value is written to the fixture, source tree, or logs
