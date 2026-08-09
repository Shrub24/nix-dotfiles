## Why

The niri compositor configuration is imperative and machine-local: `~/.config/niri/config.kdl` lives only on this Arch host, versioned by nothing, and its desktop shell layer is hand-rolled DMS (Dank Material Shell) with IPC binds scattered through the config. The niri native home-manager module (`wayland.windowManager.niri`) has shipped upstream, and Noctalia v5 (the direct replacement for the DMS shell layer) ships an official home-manager module. Both can now be fully declarative and reproducible from this flake.

## What Changes

- Add `modules/home/niri.nix` (imported by `modules/default.nix`, always-on like `tmux.nix`/`wezterm.nix`): enables `wayland.windowManager.niri` with `settings` (structured nodes) + `extraConfig` (binds, window rules) and `checkConfig` build-time validation via `niri validate`.
- Add `noctalia` flake input (`inputs.nixpkgs.follows = "nixpkgs"`), import `inputs.noctalia.homeModules.default`, configure `programs.noctalia` with `package = pkgs.noctalia` (nixpkgs' prebuilt 5.0.0-beta.7, not upstream's own derivation) and declarative `settings`.
- Replace DMS IPC binds with `noctalia msg` equivalents (launcher, control center, settings, volume, brightness, lock, window switcher); drop the obsolete quickshell `layer-rule`.
- Add Noctalia niri integration: `spawn-at-startup "noctalia"`, floating window rule for `dev.noctalia.Noctalia`, `debug.honor-xdg-activation-with-invalid-serial`.
- Commit the current imperative `config.kdl` into the repo as a pre-migration backup.
- **BREAKING**: `~/.config/niri/config.kdl` becomes a home-manager-managed store symlink; DMS (`dms` package, `~/.config/niri/dms`, its binds) is retired from the config.

## Capabilities

### New Capabilities
- `niri-home-manager`: niri compositor configuration declaratively managed via the native `wayland.windowManager.niri` module (package, settings/extraConfig KDL rendering, build-time validation, portal + systemd wiring).
- `noctalia-shell`: Noctalia v5 desktop shell declaratively managed via the upstream `programs.noctalia` module and integrated with niri (autostart, window rules, IPC keybinds replacing DMS).

### Modified Capabilities
<!-- None: no existing spec behavior changes. -->

## Impact

- `flake.nix`: new `noctalia` input; `modules/default.nix`: new import; new file `modules/home/niri.nix`.
- Home-manager state: `~/.config/niri/config.kdl` (now store-linked), `~/.config/noctalia/*.toml` (rendered from `programs.noctalia.settings`).
- Packages: `niri` (nixpkgs unstable, 26.04), `xwayland-satellite`, `xdg-desktop-portal-gnome`, `noctalia` 5.0.0-beta.7.
- Arch cleanup: disable DMS autostart/greeter while retaining its package and config temporarily, remove the Arch niri package, and manage greetd plus niri session entries through system-manager.
- Keybind conflict to resolve: `Mod+Space` currently launches the vicinae launcher; Noctalia docs bind it to the Noctalia launcher.
