# storage-topology Delta

## ADDED Requirements

### Requirement: The data disk topology is declared once per host

Each host SHALL declare its storage topology — device UUID, subvolume
names, mountpoints, and the churn/nodatacow path sets — in one typed
declaration, and every projection that consumes it SHALL derive from it. A
class-level module SHALL NOT restate a device UUID or subvolume name the
declaration already carries. The NixOS `fileSystems` for the data disk are
that declaration's projection; the install target's root mounts derive from
the separate disk declaration.

#### Scenario: One fact, several projections

- **WHEN** the data disk's UUID or a subvolume name is changed in the
  declaration
- **THEN** every projection renders the new value without a second edit

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

Paths in the declaration's `nodatacow` set SHALL be created with the `+C`
attribute so random-write and SQLite workloads (container storage, browser
profiles) do not fragment under CoW. Paths whose payloads benefit from
compression (caches) SHALL NOT be in the set.

#### Scenario: Attribute present at creation

- **WHEN** a path in the `nodatacow` set is first created
- **THEN** it carries the `+C` attribute before any data lands in it

### Requirement: NixOS-side timers and disk layout are prewired

The NixOS projection SHALL carry declarative snapper timer and retention
configuration and a disko configuration capturing the install target's
partition/subvolume layout. These MAY exceed what the current host realizes
today; they MUST match the target state so install day consumes them
without redesign.

#### Scenario: Install-day evaluation

- **WHEN** the bare-metal NixOS configuration is evaluated against the
  target disk
- **THEN** the disko configuration builds without modification and renders
  the subvolume set the installed root carries

### Requirement: Home paths are home-relative after migration

Consumer modules SHALL reference the user's data directories through
`home.homeDirectory`-derived paths, not the data disk's mountpoint. A
module MAY name the mountpoint only when it configures the mount itself.

#### Scenario: Consumers survive a mountpoint rename

- **WHEN** the data mountpoint changes (as `/mnt/LinuxData` → `/data`)
- **THEN** no consumer module outside the storage declaration names the
  old path
