# Tasks — Portable Host (`spectre`)

## Group 1 — Composition and registry (5)

- [x] 1.1 Add `modules/hosts/spectre.nix` composing
      `flake.nixosConfigurations.spectre` from the Home Manager aspect list in design
      D2 (embedded via `home-manager.nixosModules.home-manager`,
      `useGlobalPkgs`/`useUserPackages`) plus the NixOS aspect list in D2.

  - refs: design D1, D2; spec spectre-host "The portable host is a composed NixOS output"
  - criteria: the laptop composes a NixOS configuration only — no
    `systemConfigs` and no standalone `homeConfigurations` entry, since the
    embedded Home Manager is its only configuration path
  - verify: `nix eval .#nixosConfigurations.spectre.config.networking.hostName`
  - done: `.#nixosConfigurations.spectre` evaluates, `networking.hostName` is `spectre`, and no `systemConfigs` or standalone HM entry exists for it

- [x] 1.2 Add `modules/hosts/spectre/_nixos.nix` (hostname `spectre`, state
      version, `en_AU.UTF-8`, `Australia/Melbourne`, importing `_hardware.nix`) and
      `modules/hosts/spectre/_home.nix` (identity, `home-manager.enable`, the lean
      program set — no grist/hermes/aichat wiring).

  - refs: design D2; spec spectre-host "The portable host is a composed NixOS output"
  - criteria: the raw modules remain outside import-tree discovery (`_` prefix)
    and are imported only by the host composition
  - done: raw modules are `modules/hosts/spectre/_nixos.nix`, `_home.nix`, `_hardware.nix` (`_` prefix keeps them out of discovery)

- [x] 1.3 Register the laptop in the fleet registry: `topology.hosts.spectre = { system; sshUser = "saurabhj"; primaryUser = { name = "saurabhj"; uid = 1000; gid = 1000; }; }`,
      and give `topology.hosts.shrub` its `sshUser = "saurabhj"` so peer aliases
      carry the right login.

  - refs: design D8; spec current-host-facts "The fleet registry stays the single source of truth"
  - verify: `nix eval .#nixosConfigurations.spectre.config.currentHost.id`
  - done: `topology.hosts.spectre` is declared in the host composition; `shrub` already carried `sshUser = "saurabhj"`

- [x] 1.4 Add the laptop's toplevel to `flake.checks.${system}`.

  - refs: design D9; spec spectre-host "The portable host is validated before install day"
  - verify: `nix build .#checks.x86_64-linux.nixos-spectre`
  - done: `.#checks.x86_64-linux.nixos-spectre` added, alongside vm-spectre-boot

- [x] 1.5 Track the host in the repository documents (`README.md` usage command,
      `ARCHITECTURE.md` overview/composition/service sections, spec index row).

  - refs: design D10; spec spectre-host
  - verify: `nix fmt -- --ci` and a repository search finds no stale
    single-host claim

## Group 2 — Aspect granularity (2)

- done: README usage line, ARCHITECTURE overview/composition/service tree, spec index row

- [x] 2.1 Move `nix.distributedBuilds` and `nix.buildMachines` out of
      `modules/nix.nix`'s NixOS aspect into a builder aspect
      (`flake.modules.nixos.builders`), leaving the `nix` aspect free of build-host
      requirements.

  - refs: design D3; spec spectre-host "Builder access is selected, not inherited"
  - criteria: `modules/nix.nix`'s `flake.modules.nixos.nix` no longer references
    `homeForgeBuilder` or `/root/.ssh/nix-remote`
  - done: `flake.modules.nixos.builders` holds `nix.distributedBuilds` and `nix.buildMachines`; the `nix` NixOS aspect no longer references the builder

- [x] 2.2 Select the builder aspect in `modules/hosts/arch.nix` and omit it from
      `modules/hosts/spectre.nix`.

  - refs: design D3
  - verify: `nix eval .#nixosConfigurations.spectre.config.nix.distributedBuilds` is false

## Group 3 — Hardware profile (4)

- done: `builders` is in the desktop's `nixosAspects`; the laptop's `nix.distributedBuilds` is false and `nix.buildMachines` is empty

- [x] 3.1 Write the intended `modules/hosts/spectre/_hardware.nix` shape ahead of
      install day: 1 GiB ESP, LUKS2 root with btrfs subvolumes, a 12 GiB swapfile
      with `resume_offset`, Intel microcode, `boot.initrd.availableKernelModules` for
      nvme/xhci/uas/i915/iwlwifi, zram, and the systemd-boot configuration limit.

  - refs: design D4, D5; spec spectre-host "Portable hardware is supported and probe-gated"
  - criteria: file is a skeleton with placeholders for device UUIDs, replaced by
    generated values on install day
  - done: `modules/hosts/spectre/_hardware.nix` written with `REPLACE-ON-INSTALL` placeholders for disk identifiers and resume parameters
  - note: `swapDevices` deliberately omits `size` — nixpkgs rewrites a swapfile whose size differs from a declared `size`, moving the extents `resume_offset` points at

- [ ] 3.2 On the live ISO, confirm the three unknowns the model does not settle:
      the SSD's real capacity (`lsblk -o NAME,SIZE,MODEL`), the existing ESP's size,
      and the fingerprint reader's USB id (`lsusb`) against the documented
      `06cb:00c9`.

  - refs: design D4
  - criteria: capacity and ESP size recorded before any partition decision;
    fingerprint finding recorded even though the expected answer is "unsupported"

- [x] 3.3 Enable the thermal/power set (thermald, `power-profiles-daemon`,
      hp-wmi charge threshold), `services.hardware.bolt.enable` for the two
      Thunderbolt 3 ports, and `hardware.firmware = [ pkgs.sof-firmware ]` for the
      ALC285 codec, all in the host's own modules rather than a shared aspect.

  - refs: design D4
  - verify: `nix eval .#nixosConfigurations.spectre.config.hardware.firmware`
    lists `sof-firmware`, and `services.thermald.enable` is true
  - done: thermald, power-profiles-daemon, `services.hardware.bolt` and `pkgs.sof-firmware` are declared in the host's own modules; all evaluate as expected

- [x] 3.4 Record the fingerprint reader as unsupported in the host file comment
      and enable no fingerprint service; note that auto-rotation additionally needs a
      userspace agent niri does not provide.

  - refs: design D4; spec spectre-host "Portable hardware is supported and probe-gated"
  - criteria: no `services.fprintd` in the laptop configuration

## Group 4 — Secrets bootstrap (4)

- done: the finding is a comment in `_hardware.nix` and no `services.fprintd` is enabled in the laptop configuration

- [x] 4.1 Land phase 1: initial composition excludes `sops-foundation`,
      `credentials`, and the `nix` aspect's `GITHUB_PAT` access-token file, so the
      first switch needs no key.

  - refs: design D7; spec secrets-ownership-model "Secrets are host-scoped"
  - verify: first switch on the installed machine completes with no sops service
  - done: `hmAspectsPhase1` (toggled by `secretsEnrolled = false`) omits `sops-foundation`, `credentials` and `nix`; the laptop's `sops.secrets` evaluates to an empty set

- [ ] 4.2 Generate the host's age key on the laptop (`age-keygen`), keep the
      private key on the machine at the user key path, and read only the public key
      out.

  - refs: design D7; spec secrets-ownership-model "Secrets are host-scoped"
  - criteria: the private key exists on exactly one machine

- [ ] 4.3 Add the laptop's public key as a recipient in `.sops.yaml` and
      re-encrypt every secret file with `sops updatekeys`.

  - refs: design D7; spec secrets-ownership-model "Secrets are host-scoped"
  - verify: every file under `secrets/` decrypts with the owner key after
    re-encryption, and each lists the new recipient

- [ ] 4.4 Land phase 2: add the secret-consuming aspects to the laptop's
      composition and switch again; confirm each rendered template decrypts.

  - refs: design D7
  - verify: `nixos-rebuild`/`nh os switch` succeeds, `systemctl --user` shows the
    sops-activated outputs present at the expected paths

## Group 5 — Install day (7)

- [ ] 5.1 Boot the official NixOS ISO, connect the network, and confirm disk
      identity by serial/WWN before any write.

  - refs: design D5; spec spectre-host "Storage is a single encrypted container with hibernation support"
  - criteria: serial/WWN recorded and matched against the machine's own hardware
    report; no partition command run before that check

- [ ] 5.2 Create the partition table: a 1 GiB ESP and one LUKS2 container for
      the remainder of the disk. No other partition, nothing unallocated.

  - refs: design D5, D6
  - verify: `lsblk` shows exactly two partitions plus the encrypted container,
    with no free space remaining

- [ ] 5.3 `cryptsetup luksFormat`, open the container, create the `@`, `@nix`,
      `@home`, `@swap` subvolumes, and the 12 GiB swapfile with NOCOW set.

  - refs: design D5
  - verify: `btrfs subvolume list` shows all four; `lsattr` shows `C` on the
    swapfile
  - note: create the file once with `btrfs filesystem mkswapfile --size 12G --uuid clear` (or a NOCOW `chattr +C` file) and never let NixOS resize it; record the offset from the same tooling

- [ ] 5.4 `nixos-generate-config --root /mnt`, hand-edit down to the minimal
      `_hardware.nix`, and replace the placeholder device identifiers with the real
      ones.

  - refs: design D5; spec spectre-host "Storage is a single encrypted container with hibernation support"
  - criteria: no `/dev/nvme*` numbering, no `/dev/sda*` path in the file —
    `by-uuid`/`by-partuuid` only

- [ ] 5.5 Clone the repository onto the target and run `nixos-install --flake .#spectre`.

  - refs: design D7
  - verify: install completes and the machine reboots into the greeter

- [ ] 5.6 Enrol TPM2 for the LUKS keyslot (`systemd-cryptenroll --tpm2-device=auto`)
      and confirm hibernation resumes.

  - refs: design D5; spec spectre-host "Storage is a single encrypted container with hibernation support"
  - verify: boot with no passphrase prompt; `systemctl hibernate` followed by
    power-on resumes the session

- [ ] 5.7 Record the resolved partition identifiers and the fingerprint finding
      back into the change's task notes and the host file comments.

  - refs: design D4, D5
  - criteria: a future reader can identify this disk without re-deriving it

## Group 6 — Single boot and remote access (3)

- [ ] 6.1 Confirm the machine is single-boot as designed: no unallocated region,
      no NTFS mount, and no Windows boot entry in the host's configuration.

  - refs: design D6; spec spectre-host "Storage is a single encrypted container with hibernation support"
  - verify: `lsblk` shows the whole disk claimed; `nix eval .#nixosConfigurations.spectre.config.boot.loader.systemd-boot.extraEntries`
    is empty

- [ ] 6.2 Reach the laptop from the desktop by its registry name over ssh (key
      authentication, password authentication off) and over mosh.

  - refs: design D8; spec spectre-host "The portable host is reachable and validated before install day"
  - verify: `ssh spectre` and `mosh spectre` both connect as `saurabhj`

- [ ] 6.3 Join the tailnet and confirm the laptop is reachable by tailnet name as
      well, with no inbound port opened on any other interface.

  - refs: design D8
  - verify: `tailscale status` lists the machine; the firewall exposes ssh/mosh
    on `tailscale0` only

## Group 7 — Validation and docs (4)

- [x] 7.1 Add a headless `vm-spectre-boot` check composing the laptop's NixOS
      aspect set with a minimal VM hardware stanza, mirroring `vm-skeleton-boot`.

  - refs: design D9; spec spectre-host "The portable host is validated before install day"
  - verify: `nix build .#checks.x86_64-linux.vm-spectre-boot`
  - done: `vm-spectre-boot` composes the laptop's NixOS aspect set with a minimal VM hardware stanza, headless

- [x] 7.2 `nix flake check --no-build --no-write-lock-file` passes with the
      laptop's aspects and toplevel included.

  - refs: spec repository-validation
  - verify: command exit status 0
  - done: `nix flake check --no-build --no-write-lock-file` → exit 0, `all checks passed!` with `nixos-spectre` and `vm-spectre-boot` in the checks set

- [x] 7.3 Confirm the desktop is unaffected: `.#arch` system-manager and
      `.#saurabhj` Home Manager outputs still evaluate and the VM checks still boot.

  - refs: spec current-host-facts
  - verify: `nix flake check --no-build` plus the two existing VM checks
  - done: `nix flake check --no-build` covers the desktop's outputs; `vm-skeleton-boot` passes; `vm-desktop` fails inside HM activation at the runtime-rendered ghostty theme **identically with and without this change** (verified by re-running it from a reverted copy), so it is a pre-existing VM-only limitation

- [x] 7.4 `nix fmt -- --ci` clean; Statix and Deadnix pass over the new files.

  - verify: `nix flake check --no-build` lint checks
  - done: `nix fmt -- --ci` clean; statix and deadnix pass over the new files and the treefmt check is part of the green flake check
  - boot run passed (`nix build .#checks.x86_64-linux.vm-spectre-boot`, exit 0, offloaded to the `home-forge` builder which advertises `nixos-test`): guest `spectre` reached multi-user, `nix --store daemon store ping` succeeded, and `nix-daemon`, `tailscaled`, `systemd-resolved`, `NetworkManager`, `sshd` and `home-manager-saurabhj` services all came up (`test script finished in 16.28s`)
