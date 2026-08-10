## Context

See proposal.md — Why. Current state that shapes the design:

- Imperative `~/.config/niri/config.kdl` (~400 lines, hand-tuned, heavy comments): structured nodes (input, layout, blur, animations, overview, cursor, workspaces, spawn-at-startup) plus a large `binds` block and 15 `window-rule` blocks with regex matches. DMS IPC binds (`dms ipc call ...`) are woven through binds; a quickshell `layer-rule` exists for DMS.
- Flake already pins `home-manager` (master, follows nixpkgs) — the native `wayland.windowManager.niri` module is available.
- nixpkgs unstable carries `noctalia` 5.0.0-beta.7, maintained by noctalia devs, tracking beta tags within ~1–2 days; upstream flake (`noctalia-dev/noctalia`) ships `homeModules.default` whose package default (`lib.mkDefault self.packages.<system>.default`) would build against our nixpkgs with a cache-miss hash.
- Host uses greetd; system-manager owns the Noctalia greeter and niri Wayland session entries.

## Goals / Non-Goals

**Goals:**
- niri config fully rendered from the flake; identical observable behavior after switch (binds, window rules, layout).
- Noctalia v5 replaces DMS with zero shell-provider overlap; DMS fully removable.
- Prebuilt binaries only: no local compilation of noctalia.

**Non-Goals:**
- Porting every KDL line into `settings` attrsets — binds and window rules stay verbatim in `extraConfig`.
- Managing system login files from home-manager; greetd and session entries belong to system-manager.
- Full Noctalia theming work — only minimal shell config to start; iterate via hot reload.

## Decisions

**D1 — Hybrid port: `settings` for structure, `extraConfig` for binds/rules.**
`settings` carries the nodes the KDL serializer maps cleanly: `workspace`, `input`, `layout` (incl. `preset-column-widths`, `shadow`, `focus-ring`, `border`, `tab-indicator`), `blur`, `animations`, `overview`, `gestures`, `config-notification`, `cursor`, `prefer-no-csd`, `screenshot-path`, `spawn-at-startup` (incl. `"noctalia"`), `layer-rule` (kept only if still needed), `hotkey-overlay`, `window-rule` basic blocks where practical. `extraConfig` holds the ~250-line `binds` block and the regex-heavy `window-rule` blocks verbatim.
*Rationale*: repeated same-name nodes (15 `window-rule`, many `match` lines, nested gradients) become `_children`/`_props` soup with zero behavior gain; KDL stays diffable. `checkConfig` still validates the merged output, so structural mistakes are caught at build time either way.
*Alternative rejected*: full settings port (high churn, review noise) and everything-in-extraConfig (loses the module's structured config point).

**D2 — Noctalia: flake input with `inputs.nixpkgs.follows` + `programs.noctalia.package = pkgs.noctalia`.**
Single nixpkgs in the closure; the module's `mkDefault` package is overridden to nixpkgs' derivation, which is prebuilt on cache.nixos.org and identical to upstream's (same tag, same stb override). Cachix route rejected: second nixpkgs input, unverifiable CI warmth, only buys main-branch commits between tags.
*Escalation path*: if a main-branch fix is needed before the next tag, temporarily drop `follows` and add `noctalia.cachix.org`.

**D3 — Mod+Space stays on vicinae.**
Noctalia launcher binds go to the documented IPC binds that don't collide: `Mod+S` control-center, `Mod+Comma` settings-toggle (currently DMS settings), `Alt+Tab` window-switcher stays niri's. Noctalia launcher gets no keybind initially (accessible via panel toggle IPC if desired).
*Rationale*: don't churn muscle memory mid-migration; launcher choice is a one-line bind change later.

**D4 — Lock/volume/brightness binds re-point to `noctalia msg`.**
`Ctrl+Alt+L` → `noctalia msg session lock`; `XF86AudioRaiseVolume/LowerVolume/Mute`, `XF86AudioMicMute`, `XF86MonBrightnessUp/Down` → `noctalia msg volume-*`/`brightness-*`. DMS-only binds without noctalia equivalents (notepad, processlist, dankdash wallpaper, notification center) are dropped or mapped to available IPC (`panel-toggle control-center` covers notifications). Full IPC surface enumerated at implementation time via `noctalia msg --help`.

**D5 — Module placement: `modules/home/niri.nix`, always-on.**
Matches `tmux.nix`/`wezterm.nix` convention (no enable toggle at host level); imported by `modules/default.nix`. Both `wayland.windowManager.niri` and `programs.noctalia` blocks live in this one module — one concern: the Wayland desktop session.

**D6 — Rollback = git.**
The pre-migration `config.kdl` is committed to the repo (`niri.config.kdl.imperative-backup` at the repo root) before the first switch; rollback is restoring that file and `nh home switch` with the change reverted.

**D7 — System-manager owns the login boundary.**
`modules/system/greeter.nix` configures greetd for Noctalia Greeter and installs niri session entries through tmpfiles. Session commands use absolute nix-store paths so greetd and UWSM do not depend on a login-shell `PATH`.

**D8 — Monique owns mutable monitor profiles.**
Home Manager installs Monique from its upstream flake and starts `moniqued`, but does not manage Monique's `monitors.kdl`, settings, or profile JSON. The store-linked niri config declares an unmarked optional include for `monitors.kdl`; Monique recognizes it as user-authored and does not try to mutate `config.kdl`. Inline niri output blocks and Shikane autostart are removed so only one hotplug daemon applies layouts.
*Rationale*: monitor topology changes across docks and locations; Monique keeps desired state in a persistent config while providing a Niri-native editor and hotplug profiles. Nix owns the tool and boundary, not frequently changing hardware state.

**D9 — Nirius follows upstream while nixpkgs trails.**
`pkgs/nirius/default.nix` reuses the nixpkgs Rust packaging pattern but pins SourceHut tag `nirius-0.9.0` with fixed source and Cargo hashes. The overlay exposes it as `pkgs.nirius`; Home Manager installs both binaries and niri starts `niriusd` directly.
*Rationale*: nixpkgs currently provides 0.8.0 and upstream has no flake. A small project-local derivation is less machinery than another source-management workflow and can be deleted once nixpkgs catches up.

**D10 — Noctalia Greeter follows its upstream flake and keeps mutable sync state.**
The greeter package is pinned independently at 1.2.1 and shared by system-manager and Home Manager. System-manager owns the greetd session, declarative `greeter.toml`, and a polkit rule allowing only the active local user to apply appearance state without prompting; Noctalia owns mutable `sync.toml` and synchronized appearance/output assets. UWSM output is sent to the journal rather than the greeter VT.
*Rationale*: the pinned nixpkgs greeter predates output-layout sync and clean VT logging; one upstream package avoids helper/protocol drift without updating all of nixpkgs.

## Risks / Trade-offs

- [niri option/KDL drift] → `checkConfig` validates against the same nixpkgs niri binary used by the session entries.
- [Noctalia beta config churn between versions] → minimal `settings` initially; hot reload makes iteration cheap; `niri validate`+`noctalia` runtime errors surface immediately on next login.
- [GUI overrides in `~/.local/state/noctalia/settings.toml` silently override declarative config] → documented precedence boundary (see specs — noctalia-shell); clear the state file during early iteration.
- [First switch replaces the imperative config.kdl] → D6 backup; home-manager activation is the atomic point.
- [Early login environment lacks Home Manager profile paths] → greetd, niri, and UWSM session commands use absolute store paths.
- [Monique runtime state is outside Git] → keep `~/.config/monique` and `~/.config/niri/monitors.kdl` in normal user backups; do not store-link files Monique must write.
