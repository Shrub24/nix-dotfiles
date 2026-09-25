# Tasks — Migrate `/home` to the data disk

## 1. Declaration

- [ ] Add `modules/hosts/legion/_storage.nix`: `storage.dataDisk` with
      device UUID, `homeSubvol = "@home"`, `dataSubvol = "@data"`,
      `mountpoint = "/data"`, `homeChurn` list, `nodatacow` list.
- [ ] Render `@data`'s `.snapshots` from the declaration (the data snapper
      config targets the subvol, so snapshots must not recurse).
- [ ] Cross-check the churn set against the live recon (six indices,
      `~/.cache`, `~/.local/{share,state}`, container storage, the seven
      package stores, `~/.mozilla`) — no known-churn path left on a
      snapshot path.

## 2. system-manager projection (Arch)

- [ ] Mount units for `/home` and `/data` from the declaration; remove the
      two fstab lines at cutover (runbook Phase 2, step 3).
- [ ] `storage-skeleton.service` oneshot: per-path guarded creation of
      `@home`, `@data`, `.snapshots` subvols and every `homeChurn` path;
      `chattr +C` on the `nodatacow` set at creation; `Before=home.mount`.
- [ ] Snapper configs (`root`, `home`, `data`) via
      `environment.etc."snapper/configs/…"` with retention ported from the
      captured imperative configs; `data.SUBVOLUME = /data`.

## 3. NixOS projection (prewired, superset of the live host)

- [ ] `fileSystems."/home"` and `."/data"` in
      `modules/hosts/legion/_hardware.nix` from the declaration; switch
      `/mnt/LinuxData` to `/data`.
- [ ] Declarative `services.snapper` timers + retention on the NixOS side
      (values from the same captured configs); notify registration for the
      snapper timer units per the fleet's `notify` contract.
- [ ] `modules/hosts/legion/_disko.nix` capturing both disks' target
      partition/subvolume layout; unimported but evaluated.
- [ ] Eval assertion: disko renders exactly the declaration's subvol set;
      `fileSystems."/home"` present.

## 4. Consumers

- [ ] `modules/agents/pi.nix`: eleven `/mnt/LinuxData/Projects` paths →
      `home.homeDirectory`-derived paths (only after `~/Projects` is real —
      runbook Phase 3).
- [ ] Grep gate: no module outside `_storage.nix` names
      `/mnt/LinuxData`, `/data`, or the data-disk UUID.

## 5. Operator migration + verification

- [ ] Run `docs/runbooks/migrate-home-to-data-disk.md` Phases 1–3
      (operator-run; runbook already written).
- [ ] Post-boot: `findmnt /home /data` shows both mounts on
      `47fa5ee2-…`; `btrfs subvolume list` matches the declaration;
      `snapper -c home list` lists snapshots of the new subvol.
- [ ] Confirm uv reflinks: a fresh `uv sync` in one research workspace
      shares extents with the global cache (`filefrag` or a du drop).
- [ ] Rollback path intact: root disk's `@home` unmounted but present.
- [ ] `nix flake check --no-build --no-write-lock-file` green; openspec
      validates.
