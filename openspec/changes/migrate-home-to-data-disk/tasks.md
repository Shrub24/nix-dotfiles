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
- [x] Declarative `services.snapper` timers + root/home retention on the
      NixOS side (values from the same captured configs).

  - done: `modules/hosts/legion/_nixos.nix` declares `services.snapper` with
    `configs.root` and `configs.home`, ported from the captured imperative
    configs.

- [ ] Notify registration for the snapper timer units per the fleet's `notify`
      contract.

  - reason: still open — `services.notify.events` registers niks3, home-manager
    and syncthing only; no snapper unit is registered.

- [x] `modules/hosts/legion/_disko.nix` capturing the install target's
      partition/subvolume layout, imported by the host composition.

  - done: the disko declaration describes the Samsung disk and is imported at
    `modules/hosts/legion.nix`; the data disk intentionally stays outside it,
    because disko must never repartition the disk holding the live home.

- [x] Realize the `nodatacow` set — the attribute has no declarative owner (D2).

  - done: `docs/runbooks/migrate-home-to-data-disk.md` applies `chattr +C` to
    the container and browser paths during the migration; disko cannot set it.

- [ ] Eval assertion: `fileSystems."/home"` present and derived from the
      declaration.

  - reason: still open — `fileSystems."/home"` and `."/data"` derive from the
    declaration, but no eval assertion enforces it.

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

  - reason: still open — `UV_LINK_MODE=clone` is declared, but no reflink
    confirmation has been recorded.

- [ ] Rollback path intact: root disk's `@home` unmounted but present.

  - reason: still open — the root-disk `@home` is untouched by the migration
    but has not been verified as unmounted-and-present after the change.

- [x] `nix flake check --no-build --no-write-lock-file` green; openspec
      validates.
