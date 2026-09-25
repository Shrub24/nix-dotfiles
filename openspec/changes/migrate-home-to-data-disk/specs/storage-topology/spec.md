# storage-topology Delta

## ADDED Requirements

### Requirement: The data disk topology is declared once per host

Each host SHALL declare its storage topology — device UUID, subvolume
names, mountpoints, and the churn/nodatacow path sets — in one typed
declaration, and every class-level projection (mount units, `fileSystems`,
disko, snapper) SHALL derive from it. A class-level module SHALL NOT
restate a device UUID or subvolume name the declaration already carries.

#### Scenario: One fact, two projections

- **WHEN** the data disk's UUID or a subvolume name is changed in the
  declaration
- **THEN** both the system-manager and NixOS projections render the new
  value without a second edit

#### Scenario: The desktop NixOS output declares the home mount

- **WHEN** the NixOS host composition is evaluated
- **THEN** `fileSystems."/home"` and `fileSystems."/data"` are present and
  derived from the declaration

### Requirement: `/home` is a `@home` subvolume on the data disk

`/home` SHALL be the declaration's `homeSubvol` subvolume on the data disk,
not a subvolume of the root disk. `/data` SHALL be the declaration's
`dataSubvol` subvolume on the same disk, replacing a top-level
`/mnt/LinuxData` mount.

#### Scenario: Mounted topology

- **WHEN** the host is booted after migration
- **THEN** `/home` resolves to the data disk's `@home` and `/data` to its
  `@data`
- **AND** the root disk's `@home` is no longer mounted anywhere

### Requirement: Churn paths are subvolumes and skip home snapshots

Each churn path in the declaration SHALL exist as a nested subvolume under
the home subvolume, so btrfs snapshots of the home subvolume exclude it.
The declaration SHALL distinguish churn paths (regenerable state:
caches, indices, container storage, package stores) from preserved paths
(dotfiles, documents, projects), and only churn paths appear in the set.

#### Scenario: Snapshot excludes the churn set

- **WHEN** a snapshot of the home subvolume is created
- **THEN** no file under a churn path is captured by it
- **AND** files under non-churn home paths are captured

#### Scenario: The churn set is complete for the declared packages

- **WHEN** a tool known to write high-churn state is added to the
  configuration and its state directory is under a preserved path
- **THEN** its state path is added to the churn set rather than left in a
  snapshot path

### Requirement: Nodatacow applies where CoW harms

Paths in the declaration's `nodatacow` set (container storage, browser
profiles) SHALL be created with the `+C` attribute so random-write and
SQLite workloads do not fragment under CoW. Paths whose payloads benefit
from compression (caches) SHALL NOT be in the set.

#### Scenario: Attribute present at creation

- **WHEN** the skeleton realizes a nodatacow path
- **THEN** the subvolume is created empty and the `+C` attribute is set
  before any data lands in it

### Requirement: The skeleton is idempotent and additive

The class that can create subvolumes SHALL do so through an idempotent,
guarded mechanism that creates a declared subvolume only when absent, and
SHALL NOT delete, move, or rewrite any existing path. An already-created
subvolume SHALL survive re-runs unchanged.

#### Scenario: Re-run after full realization

- **WHEN** the skeleton runs again on a host where every declared subvol
  exists
- **THEN** nothing is created, moved, or deleted

#### Scenario: Partial realization converges

- **WHEN** a declared subvolume is absent but its parent directory exists
- **THEN** the skeleton creates it and leaves any contents already at that
  path untouched

### Requirement: system-manager realizes mounts declaratively

On the non-NixOS host, the data disk's home and data mounts SHALL be
realized as systemd mount units generated from the declaration — not as
hand-edited fstab lines — so the mount topology is evaluation-visible.
Boot-critical mounts (root, `/nix`, `/boot`) remain outside this contract.

#### Scenario: Mount unit renders from the declaration

- **WHEN** the system-manager configuration is evaluated
- **THEN** the home and data mount units exist with the declared
  device-UUID and subvolume options

### Requirement: NixOS-side timers and disk layout are prewired

The NixOS projection SHALL carry declarative snapper timer and retention
configuration and a disko configuration capturing both disks' target
partition/subvolume layout. These MAY exceed what the current host realizes
today; they MUST match the target state so install day consumes them
without redesign.

#### Scenario: Install-day evaluation

- **WHEN** the bare-metal NixOS configuration is evaluated against the
  target disks
- **THEN** the disko configuration builds without modification and renders
  the same subvolume set the declaration names

### Requirement: Home paths are home-relative after migration

Consumer modules SHALL reference the user's data directories through
`home.homeDirectory`-derived paths, not the data disk's mountpoint. A
module MAY name the mountpoint only when it configures the mount itself.

#### Scenario: Consumers survive a mountpoint rename

- **WHEN** the data mountpoint changes (as `/mnt/LinuxData` → `/data`)
- **THEN** no consumer module outside the storage declaration names the
  old path
