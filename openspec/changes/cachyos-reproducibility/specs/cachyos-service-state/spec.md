## Purpose

Defines the intended CachyOS system and user service state, its ownership boundaries, and the safeguards around privileged activation.

## ADDED Requirements

### Requirement: Service intent has one authority
Each required CachyOS service or system integration SHALL have one explicit setup authority, separate from package declaration, and package migration SHALL NOT preserve privileged Metapac shell hooks as a second authority.

#### Scenario: Service authority map is inspected
- **WHEN** service and system setup paths are enumerated
- **THEN** each intended action has one declared owner
- **AND** no Declarch package entry duplicates the same privileged setup through a copied Metapac hook

### Requirement: Intended user services are activatable
Chezmoi's finite CachyOS setup SHALL own activation for the following user units, except that the authored Hyprland configuration SHALL start `hyprland-session.target`. The deployment SHALL produce this state:

- `dms.service`: package-owned; enabled and running in the graphical user session.
- `hyprpolkitagent.service`: package-owned; enabled and running in the graphical user session to provide authorization prompts for GUI applications requesting elevated privileges.
- `kanata.service`: Chezmoi-owned; enabled and running for the user.
- `kanata-switcher.service`: package-owned; enabled and running for the user.
- `openrazer-daemon.service`: package-owned; enabled and running for the user.
- `hyprland-session.target`: Chezmoi-owned; started by Hyprland for the session and not enabled as a persistent user unit.

#### Scenario: Disposable acceptance reaches user session
- **WHEN** an approved disposable acceptance machine completes bootstrap and starts the user session
- **THEN** every listed unit has the exact owner and enabled/running state declared above
- **AND** package-supplied units and Chezmoi-authored units resolve from their respective owners

### Requirement: Intended system services are activatable
The CachyOS base installer and Chezmoi's finite CachyOS setup SHALL each own only the package-owned system-unit activation assigned below. The deployment SHALL produce this state:

- `greetd.service`: package-owned unit configured and enabled through the packaged `dms-greeter` CLI invoked by Chezmoi; started by the normal boot target.
- `NetworkManager.service`: package-owned and enabled by the minimal no-desktop CachyOS installer; Chezmoi does not duplicate its activation.
- `bluetooth.service`: package-owned; enabled and running through Chezmoi because CachyOS enables it only for installer-selected desktop profiles.
- `sshd.service`: package-owned with explicit Chezmoi setup; enabled and running.
- `ufw.service`: package-owned and configured through UFW; enabled with the firewall active.
- `cups.socket` and `cups.path`: enabled and running through Chezmoi because CachyOS enables printing only for installer-selected desktop profiles; `cups.service`: enabled and activatable through those native units.
- `libvirtd.service`: enabled and activatable through libvirt's native unit relationships; it is not required to run continuously while idle.

#### Scenario: Disposable acceptance reaches system targets
- **WHEN** an approved disposable acceptance machine completes bootstrap
- **THEN** every listed unit has the exact owner and enabled/running or native-activation state declared above
- **AND** an enabled Infinity service not declared as intent is not copied automatically

### Requirement: DMS configuration does not duplicate package installation
DMS-native setup SHALL use the standalone packaged `dms-greeter` CLI to enable greetd and sync DMS theme/settings only after declared packages exist, and SHALL NOT independently install packages already owned by the package declaration.

#### Scenario: Desktop setup executes
- **WHEN** DMS desktop or greeter setup runs after package provisioning
- **THEN** it uses application-native configuration behavior
- **AND** it does not invoke a second package installation path for declared packages

### Requirement: Privileged mutations are explicit and approval-bounded
Group membership, udev, PAM, greetd, SSH, UFW, fstab, and service enablement changes SHALL be visible as explicit CachyOS setup actions and SHALL NOT execute during non-mutating fixture validation.

#### Scenario: Fixture validation covers privileged setup
- **WHEN** service setup is exercised in a fixture
- **THEN** harmless substitutes receive the intended arguments and paths
- **AND** no real systemctl, firewall, package, credential, group, mount, or `/etc` mutation occurs

#### Scenario: Real privileged acceptance is requested
- **WHEN** real service setup is required for end-to-end verification
- **THEN** it runs only after explicit approval on the disposable acceptance machine
- **AND** it never targets Infinity

### Requirement: Machine-specific service state remains machine-specific
Infinity-specific mounts, symlinks, hardware setup, and similar behavior SHALL NOT become unconditional CachyOS machine-class service state.

#### Scenario: Future CachyOS host lacks Infinity identity
- **WHEN** the deployment runs on a CachyOS host other than Infinity
- **THEN** Infinity-specific vault mount and hardware actions are not applied
- **AND** the shared CachyOS user experience remains deployable
