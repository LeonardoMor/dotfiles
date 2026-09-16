## Purpose

Defines the observable contract for turning a minimal CachyOS installation into the declared workstation state through one fail-closed bootstrap invocation.

## ADDED Requirements

### Requirement: CachyOS-only bootstrap scope
The bootstrap SHALL select the CachyOS machine class only when Chezmoi data contains the exact selector `.osid == "linux-cachyos"` and SHALL NOT claim support for macOS, Windows, generic Arch, or another Linux distribution.

#### Scenario: Exact CachyOS selector is accepted
- **WHEN** bootstrap runs with Chezmoi data whose `.osid` is exactly `linux-cachyos`
- **THEN** it selects the CachyOS machine-class deployment
- **AND** it does not require the hostname to be `infinity`

#### Scenario: Non-matching selector is rejected
- **WHEN** bootstrap runs with a missing or different `.osid` value
- **THEN** it exits with a clear unsupported-system diagnostic
- **AND** it does not begin package or Chezmoi mutation

### Requirement: One-invocation deployment
A successful bootstrap invocation SHALL execute exactly one Chezmoi apply through `chezmoi init --apply` and complete the reviewed package, user-environment, and service setup phases without a second manual or automated `chezmoi apply`.

#### Scenario: Bootstrap succeeds
- **WHEN** bootstrap finishes successfully with required prerequisites and credentials available
- **THEN** the Chezmoi apply phase has completed
- **AND** no second manual or automated `chezmoi apply` occurs

#### Scenario: Deployment phase fails
- **WHEN** any required bootstrap or Chezmoi deployment phase fails
- **THEN** bootstrap exits unsuccessfully
- **AND** it does not report the workstation as deployed

### Requirement: Minimal bootstrap prerequisites
Bootstrap SHALL install or obtain only the prerequisites needed to retrieve the source and execute the declared deployment; steady-state package intent SHALL remain in the selected package declarations.

#### Scenario: Prerequisite installation completes
- **WHEN** a required bootstrap prerequisite is absent on minimal CachyOS
- **THEN** bootstrap installs or obtains that prerequisite
- **AND** the later package phase remains authoritative for steady-state package intent

#### Scenario: Declarch is absent
- **WHEN** bootstrap obtains Declarch through its official prebuilt-release installer
- **THEN** the installer source is pinned and checksum-verified before execution
- **AND** the official installer verifies the selected release archive checksum
- **AND** any verification or installation failure stops bootstrap before Chezmoi apply

### Requirement: Credential failure is closed
Bootstrap SHALL NOT expose, persist, or substitute secret values, and a required unavailable credential SHALL stop or omit only the dependent feature with a clear diagnostic.

#### Scenario: Required 1Password access is unavailable
- **WHEN** a required template value cannot be retrieved from 1Password
- **THEN** bootstrap does not render a placeholder or secret value into source or logs
- **AND** it exits unsuccessfully or explicitly reports the dependent feature as omitted

#### Scenario: Fresh machine has no configured 1Password account
- **WHEN** 1Password CLI is installed but has no configured account
- **THEN** bootstrap interactively adds and signs in to the account
- **AND** it verifies the authenticated session before Chezmoi apply
- **AND** account-addition or authentication failure stops bootstrap without exposing credentials

### Requirement: Infinity remains read-only
No operation in this change SHALL apply configuration, mutate packages, alter services, or change credentials on Infinity.

#### Scenario: Verification references Infinity
- **WHEN** implementation or verification needs reference-state evidence from Infinity
- **THEN** only read-only inspection is performed
- **AND** no acceptance run targets Infinity

### Requirement: End-to-end acceptance boundary
Real convergence from minimal CachyOS SHALL be considered verified only by an explicitly approved run on a disposable machine; otherwise it SHALL be reported as unverified.

#### Scenario: Disposable acceptance is approved
- **WHEN** explicit approval is given for end-to-end acceptance
- **THEN** bootstrap runs on a disposable minimal-CachyOS machine
- **AND** its resulting package, user-environment, and service state is compared with the specifications

#### Scenario: Disposable acceptance is not approved
- **WHEN** the checkpoint pull request is prepared without an approved disposable acceptance run
- **THEN** end-to-end convergence is listed as unverified
- **AND** static or fixture validation is not described as equivalent evidence
