# Tasks — service scope ownership

## Group 1 — Surge daemon becomes a user service (5)

- [x] 1.1 Rewrite `flake.modules.homeManager.surge` as package + `systemd.user`
  unit (`server start --port 1700 --output ${home}/Downloads`, `Restart = "on-failure"`, `RestartSec = "5s"`, `WantedBy = default.target`).

  - refs: design D1, D2; spec surge-download-manager "Home Manager installs the
    package and its user daemon"
  - verify: `nix eval .#homeConfigurations.saurabhj.config.systemd.user.services.surge.Service.ExecStart`

- [x] 1.2 Delete `flake.modules.nixos.surge`.

  - refs: design D1; spec surge-download-manager REMOVED requirement
  - verify: no `flake.modules.nixos.surge` in `modules/`

- [x] 1.3 Drop `"surge"` from `embeddedHmAspects`' subtract list in
  `modules/hosts/arch.nix` and update the comment naming the system-owned
  duplicates.

  - refs: design D1; spec surge-download-manager "Both hosts behave identically"
  - verify: the NixOS desktop's embedded Home Manager exposes the `surge` user
    unit and `pkgs.surge-downloader` in `home.packages` (both were absent before)

- [x] 1.4 Confirm `surge` is not in `nixosAspects` (it never was) and that no
  system unit remains on any host.

  - refs: proposal "The aspect was never selected"
  - verify: `nix eval .#nixosConfigurations.shrub.config.systemd.services` has no
    `surge` key

- [x] 1.5 Record the finding that no upstream or bundled unit exists (nixpkgs
  package ships none, upstream repo has none, `surge service install` is
  imperative, the upstream flake module injects its own overlay) in the module
  comment and design D2.

  - refs: design D2

## Group 2 — GC has one owner per host scope (3)

- [x] 2.1 Set `programs.nh.clean` (system-scope, `nh clean all --keep-since 7d`,
  weekly) in `flake.modules.nixos.nix`.

  - refs: design D3
  - verify: `nix eval .#nixosConfigurations.shrub.config.systemd.services.nh-clean.script`

- [x] 2.2 Gate the Home Manager timer on `targets.genericLinux.enable` so it runs
  on the non-NixOS host and stays off on NixOS.

  - refs: design D3, D4
  - verify: Arch standalone HM `enable = true`; NixOS embedded HM
    `enable = false`

- [x] 2.3 Note the accepted asymmetry: the Arch system profile has no declarative
  collector (system-manager has neither `nix.gc` nor an nh module).

  - refs: design D4

## Group 3 — Documentation and validation (3)

- [x] 3.1 `ARCHITECTURE.md`: list the surge daemon among the active user
  services, remove `surge` from the system-owned aspect subtraction list, and
  record the single-owner GC rule.

  - refs: proposal "Documentation follows"

- [x] 3.2 Run the canonical validation:
  `nix flake check --no-build --no-write-lock-file`, plus `nix fmt` — green
  (`all checks passed!`).

- [x] 3.3 Archive this change once 3.2 is green, applying the
  `surge-download-manager` delta to the canonical spec.
