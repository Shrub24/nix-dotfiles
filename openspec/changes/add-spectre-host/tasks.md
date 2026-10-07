# Tasks — Portable Host (`spectre`)

## Group 1 — Composition and registry (5)

- [x] 1.1 Add `modules/hosts/spectre.nix` composing
      `flake.nixosConfigurations.spectre` from the Home Manager aspect list in design
      D2 (embedded via `home-manager.nixosModules.home-manager`,
      `useGlobalPkgs`/`useUserPackages`) plus the NixOS aspect list in D2.

  - refs: design D1, D2; spec spectre-host "The portable host is a composed NixOS output"
  - criteria: the laptop composes a NixOS configuration only, with the
    embedded Home Manager as its only configuration path
  - verify: `nix eval .#nixosConfigurations.spectre.config.networking.hostName`
  - done: `.#nixosConfigurations.spectre` evaluates, `networking.hostName` is `spectre`, and the host composes a single NixOS configuration.

- [x] 1.2 Add `modules/hosts/spectre/_nixos.nix` (hostname `spectre`, state
      version, `en_AU.UTF-8`, `Australia/Melbourne`, importing `_hardware.nix`) and
      `modules/hosts/spectre/_home.nix` (identity, `home-manager.enable`, the lean
      program set — no grist/hermes/aichat wiring).

  - refs: design D2; spec spectre-host "The portable host is a composed NixOS output"
  - criteria: the raw modules remain outside import-tree discovery (`_` prefix)
    and are imported only by the host composition
  - done: raw modules are `modules/hosts/spectre/_nixos.nix`, `_home.nix`, `_hardware.nix` (`_` prefix keeps them out of discovery)

- [x] 1.3 Register the laptop in the fleet registry: `topology.hosts.spectre = { sshUser = "saurabhj"; primaryUser = { name = "saurabhj"; uid = 1000; gid = 1000; }; }`,
      and give `topology.hosts.legion` its `sshUser = "saurabhj"` so peer aliases
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

- [x] 2.2 Select the builder aspect in `modules/hosts/legion.nix` and omit it from
      `modules/hosts/spectre.nix`.

  - refs: design D3
  - verify: `nix eval .#nixosConfigurations.spectre.config.nix.distributedBuilds` is false

## Group 3 — Hardware profile (6)

- done: `builders` is in the desktop's `nixosAspects`; the laptop's `nix.distributedBuilds` is false and `nix.buildMachines` is empty

- [x] 3.1 Write the intended `modules/hosts/spectre/_hardware.nix` shape ahead of
      install day: 2 GiB ESP, a disko-owned LUKS2 root with btrfs subvolumes, a
      12 GiB swapfile with `resume_offset`, Intel microcode,
      `boot.initrd.availableKernelModules` for nvme/xhci/uas/i915/iwlwifi, zram,
      and the systemd-boot configuration limit.

  - refs: design D4, D5; spec spectre-host "Portable hardware is supported and probe-gated"
  - criteria: the file declares host policy and leaves the disk, its mounts and swap to the disko declaration
  - done: `modules/hosts/spectre/_hardware.nix` holds boot policy, firmware, thermald, bolt, zram and the systemd-boot limit; the disk is in `_disko.nix`
  - note: `boot.kernelParams` still carries `resume_offset=REPLACE-ON-INSTALL`, tracked in 5.6

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

- [ ] 3.5 Reconcile the laptop's selected aspect set with design D2: `libreoffice`
      and `monique` are selected in `modules/hosts/spectre.nix` although D2 and the
      proposal place both on the desktop.

  - refs: design D2; proposal "no local service tier"
  - reason: still open — the code diverges from the stated product decision, and
    the decision is not rewritten in the design to bless the divergence.
  - note: which side is authoritative is an owner call.

- [ ] 3.6 Replace the laptop disk's `/dev/nvme0n1` with a stable identity
      (by-id or by-partuuid) in `modules/hosts/spectre/_disko.nix`.

  - refs: spec spectre-host "Storage is a single encrypted container with hibernation support"
  - reason: still open — the requirement ("no kernel-assigned device number SHALL
    appear") stands, so the declaration is corrected rather than the requirement.

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

- [x] 5.1 Boot the official NixOS ISO, connect the network, and confirm disk
      identity by serial/WWN before any write.

  - refs: design D5; spec spectre-host "Storage is a single encrypted container with hibernation support"
  - criteria: serial/WWN recorded and matched against the machine's own hardware report; no partition command run before that check
  - done: the machine is installed from that declaration, and `modules/hosts/spectre/facter.json` is the committed live-media hardware report

- [x] 5.2 Create the partition table: a 2 GiB ESP and one LUKS2 container for
      the remainder of the disk. No other partition, nothing unallocated.

  - refs: design D5, D6
  - verify: `lsblk` shows exactly two partitions plus the encrypted container, with no free space remaining
  - done: `modules/hosts/spectre/_disko.nix` declares the 2 GiB ESP and the `100%` `cryptroot` container, and the installed disk was created from it

- [x] 5.3 `cryptsetup luksFormat`, open the container, create the btrfs
      subvolumes, and the 12 GiB swapfile.

  - refs: design D5
  - done: `_disko.nix` creates `@`, `@nix`, `@home`, `@snapshots`, `@persist`,
    `@log`, `@cache`, `@tmp` and `@swap` with its 12 GiB swapfile

- [x] 5.4 `nixos-generate-config --root /mnt`, hand-edit down to the minimal
      `_hardware.nix`, and replace the placeholder device identifiers with the real
      ones.

  - refs: design D5; spec spectre-host "Storage is a single encrypted container with hibernation support"
  - criteria: `_hardware.nix` declares policy only; the device tree lives in the disko declaration
  - done: `_hardware.nix` carries no mount or disk identity; the LUKS initrd device derives from the disko partlabel
  - note: `_disko.nix` still names `/dev/nvme0n1`, tracked in 3.6

- [x] 5.5 Clone the repository onto the target and run `nixos-install --flake .#spectre`.

  - refs: design D7
  - verify: install completes and the machine reboots into the greeter
  - done: `docs/runbooks/provision-spectre.md` Phase 1 installed the host from the desktop; the installed system is the current state

- [ ] 5.6 Enrol TPM2 for the LUKS keyslot (`systemd-cryptenroll --tpm2-device=auto`)
      and confirm hibernation resumes.

  - refs: design D5; spec spectre-host "Storage is a single encrypted container with hibernation support"
  - verify: boot with no passphrase prompt; `systemctl hibernate` followed by power-on resumes the session
  - reason: still open — `boot.kernelParams` still carries
    `resume_offset=REPLACE-ON-INSTALL`, and the TPM2 enrolment is a post-install
    step (`docs/runbooks/provision-spectre.md` Phase 3).

- [ ] 5.7 Record the resolved partition identifiers and the fingerprint finding
      back into the change's task notes and the host file comments.

  - refs: design D4, D5
  - criteria: a future reader can identify this disk without re-deriving it
  - reason: still open — `resume_offset` is still a placeholder, and no fingerprint
    finding is recorded under `modules/hosts/spectre/`.

## Group 6 — Single boot and remote access (3)

- [x] 6.1 Confirm the machine is single-boot as designed: no unallocated region,
      no NTFS mount, and no Windows boot entry in the host's configuration.

  - refs: design D6; spec spectre-host "Storage is a single encrypted container with hibernation support"
  - verify: `lsblk` shows the whole disk claimed; `nix eval .#nixosConfigurations.spectre.config.boot.loader.systemd-boot.extraEntries` is empty
  - done: `_disko.nix` claims the whole disk (ESP plus the `100%` container), the
    host declares no NTFS mount, and `spectre.nix` declares no Windows boot entry

- [ ] 6.2 Reach the laptop from the desktop by its registry name over ssh (key
      authentication, password authentication off) and over mosh.

  - refs: design D8; spec spectre-host "The portable host is reachable and validated before install day"
  - verify: `ssh spectre` and `mosh spectre` both connect as `saurabhj`
  - reason: still open — provisioning used `root@<ip>`, and no registry-name ssh or
    mosh session is recorded in the repository.

- [ ] 6.3 Join the tailnet and confirm the laptop is reachable by tailnet name as
      well, with no inbound port opened on any other interface.

  - refs: design D8
  - verify: `tailscale status` lists the machine; the firewall exposes ssh/mosh on `tailscale0` only
  - reason: still open — the host selects the `tailscale` aspect, but secrets are
    not enrolled and no tailnet identity is recorded.

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

- [x] 7.3 Confirm the desktop is unaffected: `.#nixosConfigurations.legion` still
      evaluates and the VM checks still boot.

  - refs: spec current-host-facts
  - verify: `nix flake check --no-build` plus the two existing VM checks
  - done: `nix flake check --no-build` covers the desktop's outputs; `vm-skeleton-boot` passes; `vm-desktop` fails inside HM activation at the runtime-rendered ghostty theme **identically with and without this change** (verified by re-running it from a reverted copy), so it is a pre-existing VM-only limitation

- [x] 7.4 `nix fmt -- --ci` clean; Statix and Deadnix pass over the new files.

  - verify: `nix flake check --no-build` lint checks
  - done: `nix fmt -- --ci` clean; statix and deadnix pass over the new files and the treefmt check is part of the green flake check
  - boot run passed (`nix build .#checks.x86_64-linux.vm-spectre-boot`, exit 0, offloaded to the `home-forge` builder which advertises `nixos-test`): guest `spectre` reached multi-user, `nix --store daemon store ping` succeeded, and `nix-daemon`, `tailscaled`, `systemd-resolved`, `NetworkManager`, `sshd` and `home-manager-saurabhj` services all came up (`test script finished in 16.28s`)
