## 1. Backup & Flake Inputs

- [x] 1.1 Commit the current imperative `~/.config/niri/config.kdl` into the repo as `niri.config.kdl.imperative-backup` (pre-migration rollback reference; `raw/` pattern is retired — backup lives at repo root)
- [x] 1.2 Add `noctalia` input to `flake.nix` (`url = "github:noctalia-dev/noctalia"`, `inputs.nixpkgs.follows = "nixpkgs"`) and run `nix flake lock` to pin it

## 2. Niri Home-Manager Module

- [x] 2.1 Create `modules/home/niri.nix` enabling `wayland.windowManager.niri` (package default, `checkConfig`, `portalPackage`, `xwaylandSatellitePackage`, systemd units)
- [x] 2.2 Port structured config nodes into `settings`: `workspace` defs, `input` (keyboard/xkb, touchpad, mouse, trackpoint), `layout` (gaps, preset-column-widths, tab-indicator, border, focus-ring, shadow, struts), `blur`, `overview`, `gestures`, `config-notification`, `cursor`, `prefer-no-csd`, `screenshot-path`, `hotkey-overlay`, `animations`, `spawn-at-startup` (existing uwsm lines + `"noctalia"`)
- [x] 2.3 Port the `binds` block and all `window-rule` blocks verbatim into `extraConfig`, replacing every `dms ipc call ...` bind with the equivalent `noctalia msg` command and dropping binds with no equivalent
- [x] 2.4 Drop the obsolete quickshell `layer-rule` (DMS-only) and add Noctalia window rules (floating `dev.noctalia.Noctalia` settings window with 1080x920 default, corner radius) plus `debug.honor-xdg-activation-with-invalid-serial`
- [x] 2.5 Import `./home/niri.nix` in `modules/default.nix`

## 3. Noctalia Configuration

- [x] 3.1 Import `inputs.noctalia.homeModules.default` in `modules/home/niri.nix` and enable `programs.noctalia` with `package = pkgs.noctalia` (nixpkgs prebuilt override)
- [x] 3.2 Set minimal declarative `settings` (theme mode/source, wallpaper) and verify the rendered TOML appears under `~/.config/noctalia/` after activation
- [x] 3.3 Enumerate the full IPC surface (`noctalia msg --help`) and finalize the binds mapping; grep the rendered config for zero remaining `dms` references

## 4. Validation & Switch

- [x] 4.1 Build the activation package (`nix build .#homeConfigurations.saurabhj.activationPackage`) — `checkConfig` runs `niri validate` on the generated KDL
- [x] 4.2 `nh home switch`, confirm niri reloads with the store-linked config and Noctalia spawns at startup; exercise lock, volume, brightness, control-center binds — switch done; login/bind test is a user acceptance step
- [x] 4.3 Disable DMS autostart/greeter while retaining its package and config temporarily; remove Arch niri, manage greetd/session entries through system-manager, and verify a clean `Niri (UWSM)` login

## 5. Docs

- [x] 5.1 Update `ARCHITECTURE.md` and `STRUCTURE.md` for the new `modules/home/niri.nix` module, noctalia input, and the retired `raw/` symlink pattern (now `appsDir`/`../apps`)

## 6. Monique Monitor Profiles

- [x] 6.1 Add the upstream `monique` flake input with nixpkgs following the project input
- [x] 6.2 Install Monique and manage `moniqued` as a Home Manager user service with graphical-session lifecycle
- [x] 6.3 Add an unmarked optional `monitors.kdl` include, remove inline niri output blocks, and mask the legacy Shikane XDG autostart
- [x] 6.4 Build and switch Home Manager; verify the service starts and niri validates the generated config
- [x] 6.5 Update architecture documentation with the Monique ownership boundary and runtime state paths

## 7. Nirius Utilities

- [x] 7.1 Add `pkgs/nirius/default.nix` pinned to SourceHut release 0.9.0 with fixed source and Cargo hashes
- [x] 7.2 Register `pkgs.nirius` in the overlay, install it with the niri module, and start `niriusd` at session startup
- [x] 7.3 Build and switch Home Manager; verify `nirius` and `niriusd`, then update architecture documentation

## 8. Greeter Integration

- [x] 8.1 Pin upstream `noctalia-greeter` 1.2.1 as a flake input and use the same package for system-manager and Home Manager
- [ ] 8.2 Route UWSM startup output to the journal and verify a clean greeter-to-session transition
- [x] 8.3 Add a fixed-path no-follow staging wrapper and dedicated polkit action; route Noctalia through it with `pkexec`, keep `systemd1.manage-units` ungranted, and confirm silent appearance sync
- [ ] 8.4 Patch Noctalia's lock screen to a dedicated `noctalia-lock` PAM service with a minimal `pam_unix` policy; verify unlock works without touching `/etc/pam.d/login`
