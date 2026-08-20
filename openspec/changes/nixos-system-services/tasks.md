# Tasks — NixOS System Services Adoption

## Group A — New nixos aspect files (5)

- [x] `A1.` Create `modules/foundation/audio.nix` publishing
  `flake.modules.nixos.audio`: `services.pipewire.enable = true`,
  `services.pipewire.audio.enable = true`, `services.pipewire.alsa.enable = true`,
  `services.pipewire.pulse.enable = true`, `services.pipewire.jack.enable = true`,
  `services.pipewire.wireplumber.enable = true`, `security.rtkit.enable = true`.
  Note: NixOS defaults pipewire to user units (not system-wide) — matches
  desktop use; don't set `systemWide = true`.

- [x] `A2.` Create `modules/foundation/bluetooth.nix` publishing
  `flake.modules.nixos.bluetooth`: `hardware.bluetooth.enable = true`,
  `hardware.bluetooth.powerOnBoot = true`.

- [x] `A3.` Create `modules/foundation/power.nix` publishing
  `flake.modules.nixos.power`: `services.upower.enable = true`,
  `services.power-profiles-daemon.enable = true`, `services.acpid.enable = true`.

- [x] `A4.` Create `modules/containers.nix` publishing
  `flake.modules.nixos.containers`: `virtualisation.podman.enable = true`,
  `virtualisation.podman.dockerCompat = true` (so `docker` CLI alias works
  since some scripts may call `docker`), `virtualisation.podman.defaultNetwork.settings.dns_enabled = true`.

- [x] `A5.` Create `modules/desktop-services.nix` publishing
  `flake.modules.nixos.desktop-services`:
  `services.gvfs.enable = true`, `services.gnome.gnome-keyring.enable = true`,
  `services.accounts-daemon.enable = true`, `services.udisks2.enable = true`,
  `services.printing.enable = true`, `hardware.openrazer.enable = true` with
  `hardware.openrazer.users = [ "saurabhj" ]`, `services.logrotate.enable = true`.
  Also add `services.avahi.enable = true` + `services.avahi.nssmdns4 = true`
  \+ `services.avahi.openFirewall = true` here (mDNS is a desktop infra concern,
  not a networking routing concern). Actually — see B1 decision: avahi goes
  in network.nix since it's name resolution. Pick one home, put it there.

  ```
  refs: A5 puts avahi in network.nix (B1). Keep desktop-services.nix for
  gvfs/gnome-keyring/accounts-daemon/udisks2/printing/openrazer/logrotate only.
  ```

## Group B — Extend existing aspect files (4)

- [x] `B1.` Extend `modules/foundation/network.nix` nixos aspect:
  add `networking.networkmanager.enable = true` (covers wpa_supplicant
  backing), `networking.networkmanager.plugins = [ pkgs.networkmanager-openconnect pkgs.networkmanager-openvpn ]`,
  `networking.firewall.enable = true`, `services.avahi.enable = true` +
  `services.avahi.nssmdns4 = true` + `services.avahi.openFirewall = true`.
  Keep existing `services.resolved.enable` + `settings.Resolve.MulticastDNS = "no"`.
  NOTE: `networking.networkmanager` conflicts with `networking.wireless` and
  `networking.dhcpcd` — only one network manager. NetworkManager is the pick.
- [x] `B2.` Extend `modules/foundation/boot.nix` nixos aspect:
  add `boot.plymouth.enable = true` and `services.btrfs.autoScrub.enable = true`
  (defaults to all btrfs mounts). Keep empty no-op comment removed or updated.
  Skip snapper configs — needs `.snapshots` btrfs subvolume setup that's an
  install-day concern; add a `ponytail:` comment noting the deferral.
- [x] `B3.` Extend `modules/ssh.nix` nixos aspect:
  add `services.openssh.enable = true` (the server side; client config stays).
  Set `services.openssh.settings.PasswordAuthentication = false` (key-only,
  more secure; the user has ed25519 keys in HM). Set
  `services.openssh.openFirewall = true` (opens port 22 in networking.firewall).
- [x] `B4.` Extend `modules/syncthing.nix` with a `flake.modules.nixos.syncthing`
  aspect: `services.syncthing.enable = true`, `services.syncthing.user = "saurabhj"`,
  `services.syncthing.dataDir = "/home/saurabhj"`, `services.syncthing.openDefaultPorts = true`.
  Do NOT set `settings.folders` or `settings.devices` — current HM config
  doesn't either; the GUI manages those and `overrideFolders`/`overrideDevices`
  default to true. Consider `services.syncthing.overrideDevices = false` and
  `services.syncthing.overrideFolders = false` so GUI-managed state isn't
  reverted on restart — but only if the current HM config also sets these.

## Group C — Host composition + VM test

- [x] `C1.` Update `modules/hosts/arch.nix` `nixosAspects` list:
  add `"audio"`, `"bluetooth"`, `"power"`, `"containers"`,
  `"desktop-services"`, `"syncthing"`. (ssh, network, boot already in list.)
  Final: `[ "foundation" "network" "boot" "ssh" "tailscale" "greeter" "nix" "nixbuild" "audio" "bluetooth" "power" "containers" "desktop-services" "syncthing" ]`
- [x] `C2.` Expand VM test assertions in `modules/hosts/arch.nix`:
  add `arch.wait_for_unit("NetworkManager.service")`,
  `arch.wait_for_unit("avahi-daemon.service")`,
  `arch.wait_for_unit("sshd.service")`,
  `arch.wait_for_unit("udisks2.service")`,
  `arch.wait_for_unit("acpid.service")`.
  Skip bluetooth (no controller in QEMU), pipewire (user-scoped, no session),
  podman (socket-activated, heavy), plymouth (graphics), upower/ppd
  (no battery in QEMU), gnome-keyring (user session), openrazer (no hardware).
  Add comment documenting what's skipped and why.
- [x] `C3.` Run all gates: `nix flake check --no-build --no-write-lock-file`,
  `nix eval .#nixosConfigurations.arch.config.system.build.toplevel.drvPath`,
  `nix build .#checks.x86_64-linux.vm-skeleton-boot`,
  `openspec validate --strict`.

## Deferred (explicit non-goals)

- [ ] `D1.` Ollama adoption (`services.ollama` with CUDA) — user deferred
- [ ] `D2.` LiteLLM side-port to `services.litellm` — blocked by Prisma OCI
  constraint (memory #452); stays HM podman
- [ ] `D3.` Snapper btrfs snapshot configs — needs `.snapshots` subvolume
  setup (install-day concern); `services.btrfs.autoScrub` covers integrity
- [ ] `D4.` `services.firewalld` — user chose `networking.firewall` (nftables)
- [ ] `D5.` `programs.noctalia.recommendedServices` bundle — user chose
  explicit per-feature declarations
