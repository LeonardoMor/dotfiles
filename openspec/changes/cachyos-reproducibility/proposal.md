## Why

The current bootstrap mixes package, desktop, service, generated-state, and historical cross-platform ownership, so a minimal CachyOS installation cannot be shown to converge to Infinity's intended user experience in one bootstrap run. This change establishes a single, testable CachyOS machine-class path while accounting for every maintained package declaration.

## What Changes

- Make one bootstrap invocation finish the Chezmoi deployment; no follow-up `chezmoi apply` is required.
- Replace the active Metapac package authority with selected Declarch modules containing 485 Arch, 5 npm, and 1 pipx declaration names; the sole deliberate omission from the 486-name Arch source is unused Alacritty.
- Keep package installation, desktop setup, and service activation under one explicit authority each; do not reproduce DMS-installed packages or package-hook shell orchestration in parallel.
- Preserve stable authored CachyOS user configuration and let applications own generated state.
- Apply the documented configuration-location rule per tool: centralize only when supported operating systems require different native destinations; do not add non-CachyOS behavior.
- Remove the unused Alacritty configuration and package declaration.
- Stop managing Discord and pavucontrol runtime-generated state.
- Keep destructive package pruning, deployment, service mutation, and credential operations behind explicit approval.
- Remove obsolete Metapac authority only after programmatic declaration parity and fixture validation.

## Capabilities

### New Capabilities

- `cachyos-bootstrap`: One-command, fail-closed bootstrap from minimal CachyOS through a completed Chezmoi deployment.
- `cachyos-package-state`: Exact Declarch-backed package intent, non-destructive preview, approved reconciliation, and migration parity.
- `cachyos-user-environment`: Stable authored shell, terminal, editor, desktop, theme, keybinding, and application configuration with explicit generated-state boundaries.
- `cachyos-service-state`: CachyOS system and user service intent with native activation and approval boundaries.

### Modified Capabilities

None. The repository has no existing OpenSpec capabilities.

## Impact

- Affected areas: `.bootstrap/`, Chezmoi initialization/data/routing, package declarations and package scripts, Linux desktop setup, systemd units and activation, generated-state sources, `.chezmoiignore`/`.chezmoiremove`, and production README workflow.
- Dependency change: Metapac authority is replaced by Declarch; official native backends are preferred, with only a minimal custom backend if the existing pipx declaration requires it.
- Safety: Infinity remains read-only throughout this change. Static fixtures are non-mutating; any real installation is restricted to a separately approved disposable minimal-CachyOS acceptance environment.
- Compatibility: this change validates only the CachyOS machine class. Existing non-CachyOS behavior is not expanded or claimed as supported.
