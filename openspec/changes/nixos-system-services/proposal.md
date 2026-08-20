# Proposal — NixOS System Services Adoption

## Context

The NixOS boilerplate and system-manager aspect side-ports are done (8 nixos
aspects: foundation, network, boot, ssh, tailscale, greeter, nix, nixbuild).
However, 18 system daemons running on the Arch host today have native NixOS
module equivalents that are NOT in our NixOS state: bluetooth, NetworkManager,
pipewire/wireplumber/rtkit, cups, podman, avahi/nss-mdns, upower,
power-profiles-daemon, udisks2, gnome-keyring, gvfs, openrazer, snapper/btrfs
auto-scrub, plymouth, firewall, acpid, accounts-daemon, logrotate. Plus
syncthing (HM→NixOS side-port candidate) and openssh (server side, currently
client-only in the nixos aspect).

## Decision

Adopt all 18 native NixOS modules as per-feature nixos aspects (user-confirmed:
per-feature over a single grab-bag or noctalia.recommendedServices bundle).
Side-port syncthing from HM to NixOS `services.syncthing` (user-scoping
preserved via `user`/`dataDir` options). Add `services.openssh.enable` to the
ssh aspect (server side). Skip ollama (deferred). Skip litellm side-port
(`services.litellm` runs native package; Prisma constraint per memory #452
requires OCI image). Use `networking.firewall` (NixOS-native nftables) over
`services.firewalld`.

## Scope

- 5 new nixos aspect files: audio, bluetooth, power, containers, desktop-services
- 4 existing aspect extensions: network (NetworkManager+firewall+avahi), boot
  (plymouth+btrfs.autoScrub), ssh (openssh server), syncthing (NixOS side-port)
- host composition: nixosAspects grows from 8 to ~15
- VM test: expand assertions for services feasible in headless QEMU
