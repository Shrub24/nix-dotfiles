## ADDED Requirements

### Requirement: Snapshots live outside the subvolume they capture

Each NixOS host SHALL reserve a `@snapshots` subvolume and mount it at
`/.snapshots`, outside the subvolume whose snapshots it holds, so a snapshot of
the root or home subvolume is not captured by the storage it exists to recover.

#### Scenario: The snapshot path is a separate subvolume

- **WHEN** the installed host's disk layout is inspected
- **THEN** `/.snapshots` resolves to that host's `@snapshots` subvolume
- **AND** the subvolume is not nested inside the subvolume it snapshots

#### Scenario: A snapshot can be created

- **WHEN** the host snapshots its root or home subvolume
- **THEN** the snapshot is stored under `/.snapshots` and appears in
  `snapper list`

### Requirement: Snapper configs name only mounted subvolumes

`services.snapper.configs` SHALL be declared declaratively for the subvolumes
that exist on the installed host, and SHALL NOT name a subvolume the host does
not mount; `/data` SHALL remain unconfigured because it holds rescue images and
cache residue rather than snapshotted user data.

#### Scenario: Configs match the installed subvolumes

- **WHEN** a host's NixOS configuration is evaluated
- **THEN** every declared `services.snapper.configs` entry names a subvolume
  present on that host
- **AND** no config is declared for the data disk

#### Scenario: Root and home are covered

- **WHEN** the desktop's installed system boots
- **THEN** `snapper list-configs` reports the root and home configs

### Requirement: Scrubbing and snapshots are both retained

`services.btrfs.autoScrub` SHALL remain enabled on every NixOS host: snapshots
answer "undo this change" and scrubbing answers "is the data still intact", and
neither replaces the other.

#### Scenario: Scrubbing stays enabled

- **WHEN** a NixOS host configuration is evaluated
- **THEN** `services.btrfs.autoScrub.enable` is true
