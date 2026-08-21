## Why

A fresh NixOS/Home Manager installation exposes filesystem assumptions hidden
by the existing Arch home directory: WezTerm expects a mutable color-scheme
file, Noctalia expects a wallpaper, and Posting expects its data directory.
User identity is also duplicated across host and feature modules instead of
flowing from the typed topology declaration.

## What Changes

- Model the host's primary user as a typed `{ name; uid; }` value declared once
  in `topology.hosts.<host>.primaryUser`, then derive NixOS and Home Manager user
  wiring from it without `specialArgs`.
- Remove duplicated username and UID literals from maintained runtime modules.
- Bootstrap mutable user paths in their owning Home Manager aspects:
  - seed WezTerm's mutable theme only when absent;
  - seed a Nixpkgs wallpaper for Noctalia only when absent;
  - create Posting's data directory.
- Keep managed files under normal Home Manager file ownership, mutable user
  paths under Home Manager user tmpfiles, and mutable system paths under NixOS
  tmpfiles only when no native module owns them.
- Verify the account wiring and generated Home Manager bootstrap declarations
  without adding headless graphics machinery to the desktop VM.
- Do not add a central tmpfiles module or create `/run/user/<uid>` from root;
  the deferred Niks3 runtime-socket concern remains out of scope.

## Capabilities

### New Capabilities

- `filesystem-bootstrap`: Feature-local ownership and first-switch creation of
  required mutable filesystem state.

### Modified Capabilities

- `dendritic-module-composition`: Primary-user identity becomes one structured,
  typed topology value consumed by host and feature composition.

## Impact

- Host composition and raw host modules under `modules/hosts/arch/`.
- Feature aspects that currently duplicate user identity or assume mutable
  paths: greeter, nix, syncthing, desktop services, Noctalia, WezTerm, and
  LiteLLM/Posting.
- The Home Manager activation and generated user tmpfiles configuration.
- No new flake input; the fallback wallpaper comes from `nixos-artwork` in
  nixpkgs.
