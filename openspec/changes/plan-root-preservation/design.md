# Design

## Context

Status: **tentative; held for review after disk growth**. These are proposed choices, not settled implementation decisions. Creating the artifacts does not approve application. See `proposal.md` for scope and `specs/root-state-persistence/spec.md` for the proposed behaviour contract.

The 2026-10-09 audit found Legion already has a systemd initrd, a LUKS-encrypted Btrfs root (`@`), independently mounted `/nix`, logs, cache and temporary subvolumes, and persistent `/home` (`@home`) and `/data` (`@data`) on LinuxData. The data disk is outside `cryptroot`. Adding a persistent subvolume on the encrypted filesystem does not inherently require repartitioning, root growth or reinstalling.

The evaluated account configuration used `users.mutableUsers = true` with no declared password source for root or the primary user. The system sops bootstrap key is externally provisioned at `/var/lib/sops-nix/key.txt`; SSH server and builder identities are restored through sops. Live vmagent and the OTLP collector use `DynamicUser` and `StateDirectory`. Recheck all observations before implementation: the shared working tree and deployed generation can differ.

`docs/impermanence.md` is an inventory, not an executable reset manifest. In particular, the blanket description of `/var/lib/private` as regenerable conflicts with the telemetry queue entries. Whole tool directories such as Bun global installations are not disposable caches either.

## Goals / Non-Goals

**Goals:**

- Make root reset, state persistence and recovery separate, inspectable mechanisms.
- Keep system secrets on encrypted storage and available before their consumers.
- Retain stable accounts, host identity and selected service data across resets.
- Use existing privilege and aspect boundaries without duplicating native service state ownership.
- Prove behaviour with actual reset/reboot tests before hardware deployment.

**Non-Goals:**

- Resetting home, changing its nested subvolumes or NOCOW attributes, or adopting Spectre.
- Clearing persistent caches, logs or queues merely because root becomes resettable.
- Moving `/nix` into the persistence module or replacing its existing mount.
- Repartitioning, growing LUKS/Btrfs, deleting Arch partitions or changing TPM enrollment.
- Claiming backups, faster boot, major space savings or a security boundary from root reset.

## Decisions

### P1 — root-only; persistent home remains a supported end state

The first candidate resets only Legion's root subvolume. Home and data remain persistent, including their existing nested subvolumes. Ephemeral home is a separate application-data migration, not a completion criterion for this change.

Nested subvolumes intentionally exclude their contents from parent snapshots. That does not make their contents disposable: Grist, keyrings, Magic Context, Syncthing and container volumes need independent backup coverage. The `migrate-home-to-data-disk` delta describes churn paths as regenerable; retain its topology, but reconcile that classification in the inventory rather than interpreting it as permission to delete those paths.

Alternative: reset root and home together. Not preferred because browser profiles, mutable desktop settings, credentials, agent archives and uncommitted projects substantially widen the loss modes. Ordinary persistent root remains acceptable if the complexity outweighs the gain.

### P2 — provisionally use Preservation

Preservation generates static systemd mount and tmpfiles configuration, requires the systemd initrd, and exposes explicit early-boot placement and mount/symlink choices. This matches the repository's native-lifecycle preference. Impermanence also supports systemd initrd; its use of scripts does not make its Nix configuration non-declarative.

The reviewed upstream revisions were Preservation `93416f4614ad2dfed5b0dcf12f27e57d27a5ab11` (last commit 2025-09-09) and Impermanence `7b1d382faf603b6d264f58627330f9faa5cba149` (2026-01-27). These are research baselines, not selected flake pins.

Preservation has lower recent maintenance activity and open machine-id/ordering issues. Impermanence is more widely exercised but has an open early-secret regression following its mount refactor. Neither project wins merely by popularity or issue count. Pin and test the selected revision; do not carry a growing set of local patches just to keep this preference. If acceptance requires substantial workarounds, reconsider Impermanence or retain persistent root.

### P3 — reset Btrfs root through systemd initrd, independently of mounts

Prefer recreating `@` from an empty Btrfs template to introducing tmpfs root. This reuses the existing filesystem and avoids another RAM-backed writable filesystem. The precise reset/retention procedure is not yet chosen.

The reset unit must run after LUKS unlock and before root is mounted, operate on a verified subvolume at the filesystem top level, and exclude `@nix`, persistence, logs and every other retained subvolume. No recursive deletion based on unchecked paths. Neither Preservation nor Impermanence supplies the reset guarantee by itself.

Root snapshots and old-root retention need a bounded policy. Keeping old roots indefinitely retains supposedly cleared data and consumes space. Removing them immediately eliminates one recovery opportunity. Resolve that policy before rollout; this plan does not silently replace the existing Snapper root configuration.

### P4 — conservative encrypted system-state coverage first

An `@persist` candidate remains inside the unlocked root filesystem. It is mounted early enough for required account/secret consumers. Do not place root bootstrap secrets on the unencrypted data disk for convenience.

Before enabling reset, classify and migrate at least:

- `/etc/machine-id` and `/var/lib/nixos`: identity and allocation state, needed early.
- `/var/lib/sops-nix/key.txt`: externally provisioned secret bootstrap identity.
- `/var/lib/tailscale`, `/var/lib/bluetooth`, saved NetworkManager profiles and relevant `/var/lib/NetworkManager` state.
- Systemd state whose continuity matters, including linger/timer state.
- `/var/lib/private`: actual DynamicUser backing directories, including telemetry queues.
- System container/application data and any useful `/root` contents, inventoried with privileges.

Preserving all `/var/lib` initially is a conservative alternative to fine-grained service entries. It reduces omission risk but also retains undeclared state and bulk data. A narrower manifest is preferable only when loss modes and ownership are verified. The initial granularity remains an approval gate.

Preservation's tmpfiles rules reassert configured directory ownership. Pinning a service's current dynamic UID is wrong; independently resetting its backing-directory ownership may conflict with systemd's id-mapped state handling. This is an inferred risk, not a reproduced failure on Legion. Test preserving the protected `/var/lib/private` parent with mode `0700` while systemd retains ownership of its children before proposing per-service overrides.

The existing `filesystem-bootstrap` contract forbids duplicate state ownership. Persistence selects durable storage; native modules must remain responsible for service initialization and service-owned permissions. Prefer feature-local declarations where the feature is locally owned, with explicit host policy for imported fleet capabilities. No generic HM-to-NixOS bridge is needed for root-only adoption.

### P5 — resolve login, single-file writes and timezone before reset

Prefer secret-backed declarative password hashes, available before account creation, over carrying an undocumented password database. Retaining mutable account state is an alternative requiring tests of activation and password changes. Never store plaintext passwords in Nix source.

Prefer persistent directories for applications that write a temporary file and rename it over the destination. File bind mounts can reject replacement; symlinks can be replaced and disconnect persistence. Test the actual write path for every remaining file entry.

Use an explicitly early, tested machine-id path rather than blindly copying Preservation's affected firstboot symlink example. Retain the existing identity rather than generating a new one during migration.

Automatic timezone is a specific unresolved case: `time.timeZone` is deliberately unset and `/etc/localtime` is runtime-selected. The static-timezone solution in generic guides does not apply. Decide whether to relearn the zone after reboot or retain the last selection through a tested mechanism; do not silently replace the automatic policy with a fixed zone or assume a generic file entry preserves its symlink semantics.

## Risks / Trade-offs

- Missing state → migrate and verify a conservative manifest before reset; add backups outside the affected filesystem.
- Late bootstrap mounts → test account creation and secret decryption in the actual initrd order.
- Missing persistence volume → fail visibly before reset or consumer startup; never substitute empty identity databases.
- Reapplied owner/mode or atomic replacement → exercise DynamicUser state and remaining file write paths across reboot and switch.
- Old-generation boot mistaken for data recovery → retain a tested reset-disabled recovery path and explicit restore procedure. A generation cannot recreate omitted data.
- Existing home snapshot gaps → preserve the topology, identify durable paths by name, and treat backup coverage separately from root persistence.
- Security expectations → persisted data can retain compromise. This is drift control, not authenticated boot or secure erasure.
- Limited payoff → most bulk already lives in retained `/nix`, home, caches and logs; expect maintenance clarity, not substantial space or speed gains.

## Migration Plan

1. Complete disk growth through its existing approval-gated change/runbook. This is the agreed operational order, not a dependency of this design.
2. Obtain fresh approval to develop this plan. Confirm module, manifest granularity, password source, timezone and root-retention/recovery choices.
3. Correct `docs/impermanence.md`, inventory privileged state, and establish independent backup/restore evidence. Copy state without losing ownership, ACLs, attributes or database consistency.
4. Build a rebooting VM fixture against pinned inputs. Prove reset boundaries, login, secret bootstrap, identity, DynamicUser writes, live switches and missing-volume failure. Evaluation-only flake checks are insufficient.
5. Prepare and verify persistent storage on Legion with reset disabled. Do not let an empty bind mount hide the old state or create replacement identities.
6. Test a reset-disabled recovery boot, build the exact target generation, and obtain explicit approval immediately before the first hardware reset.
7. Soak successive reset boots and review service state. Narrow the manifest only through separate verified changes. Leave home and Spectre alone.

## Review Gates

These are intentionally unresolved because the user requested a preliminary plan rather than implementation-ready approval:

- Preservation versus Impermanence on the pinned-nixpkgs VM results.
- Whole `/var/lib`, whole `/var/lib/private`, or verified individual service paths.
- Secret-backed password source and early bootstrap ordering.
- Automatic-timezone retention versus relearning after reset.
- Reset-disabled recovery implementation, old-root retention and Snapper root policy.

## Research Sources

Inspected 2026-10-09; upstream issue status is a dated observation, not a permanent claim. No module VM tests were executed during research.

- [Btrfs subvolumes](https://btrfs.readthedocs.io/en/latest/Subvolumes.html): snapshots are not recursive or independent backups.
- [Btrfs administration](https://btrfs.readthedocs.io/en/latest/Administration.html): NOCOW/checksum/compression trade-offs.
- [Preservation comparison](https://github.com/nix-community/preservation/blob/93416f4614ad2dfed5b0dcf12f27e57d27a5ab11/docs/src/impermanence-comparison.md) and [migration caveats](https://github.com/nix-community/preservation/blob/93416f4614ad2dfed5b0dcf12f27e57d27a5ab11/docs/src/impermanence-migration.md): static configuration, explicit early placement, parent permissions and file modes. Its older HM comparison must not be read as current standalone Impermanence support.
- [Preservation #22](https://github.com/nix-community/preservation/issues/22): firstboot machine-id example fails with systemd >=258. [#24](https://github.com/nix-community/preservation/issues/24): early mount/permission ordering concern.
- [Impermanence #294](https://github.com/nix-community/impermanence/issues/294): systemd mount refactor breaks early sops-key patterns. [#254](https://github.com/nix-community/impermanence/issues/254): private-state parent permissions.
- [Impermanence #175](https://github.com/nix-community/impermanence/issues/175) and [Preservation #28](https://github.com/nix-community/preservation/issues/28): atomic replacement of individually persisted files.
- [Impermanence #153](https://github.com/nix-community/impermanence/issues/153): timezone symlink semantics; specific behaviour is practitioner evidence and requires a local test.
- [systemd.exec](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html): DynamicUser state backing, ownership mapping and mount dependencies. [tmpfiles.d](https://www.freedesktop.org/software/systemd/man/latest/tmpfiles.d.html): directory ownership and symlink creation semantics.
