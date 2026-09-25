# Tasks — Migrate `/home` to the data disk

## 1. Declaration

- [x] Add `modules/hosts/legion/_storage.nix`: `storage.dataDisk` with
      device UUID, `homeSubvol = "@home"`, `dataSubvol = "@data"`,
      `mountpoint = "/data"`, `homeChurn` list, `nodatacow` list.
- [x] Keep `@data` as a plain storage subvolume without a `.snapshots`
      contract; its rescue images and package/cache residue do not need
      Snapper coverage.
- [x] Cross-check the churn set against the live recon (six indices,
      `~/.cache`, `~/.local/{share,state}`, container storage, the seven
      package stores, `~/.mozilla`) — no known-churn path left on a
      snapshot path.

## 2. NixOS projection (prewired, superset of the live host)

- [x] `fileSystems."/home"` and `."/data"` in
      `modules/hosts/legion/_hardware.nix` from the declaration; switch
      `/mnt/LinuxData` to `/data`.
- [ ] Declarative `services.snapper` timers + root/home retention on the
      NixOS side (values from the same captured configs); notify registration
      for the snapper timer units per the fleet's `notify` contract.
- [ ] `modules/hosts/legion/_disko.nix` capturing both disks' target
      partition/subvolume layout; unimported but evaluated.
- [ ] Realize the `nodatacow` set at install day alongside the subvolumes
      disko creates — the attribute has no declarative owner (D2).
- [ ] Eval assertion: disko renders exactly the declaration's subvol set;
      `fileSystems."/home"` present.

## 3. Consumers

- [x] `modules/agents/pi.nix`: eleven `/mnt/LinuxData/Projects` paths →
      `piExtensions`/`piOmniroute` helpers deriving from
      `home.homeDirectory` (eval-verified: same path shapes, rendered from
      `~/Projects`). Active after Phase 3 makes `~/Projects` real.
- [x] Grep gate: no module outside `_storage.nix` and `_disko.nix` names
      `/mnt/LinuxData`, `/data`, or the data-disk UUID.

## 4. Operator migration + verification

- [x] Run `docs/runbooks/migrate-home-to-data-disk.md` Phases 1–3
      (operator-run; runbook already written).
- [x] Post-boot: `findmnt /home /data` shows both mounts on
      `47fa5ee2-…`; `btrfs subvolume list` matches the declaration;
      `snapper -c home list` lists snapshots of the new subvol.
- [ ] Confirm uv reflinks: a fresh `uv sync` in one research workspace
      shares extents with the global cache (`filefrag` or a du drop).
- [ ] Rollback path intact: root disk's `@home` unmounted but present.
- [x] `nix flake check --no-build --no-write-lock-file` green; openspec
      validates.
