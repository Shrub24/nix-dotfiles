## 1. Phase 1 — Already applied (pre-existing work)

- [x] 1.1 `modules/desktop/portals.nix` — xdg-desktop-portal stack (gtk/gnome/wlr/kde) + `home.sessionVariables` (QT_QPA_PLATFORM=wayland, ELECTRON_OZONE_PLATFORM_HINT=auto, GTK_USE_PORTAL=1, TERMINAL=wezterm); `pkgs.wl-clipboard` restored (lost when cliphit was removed)
- [x] 1.2 `modules/desktop/vicinae.nix` — vicinae 0.26.2 from upstream flake (`inputs.vicinae.homeManagerModules.default`), `settings` ported from imperative `settings.json`, GUI overrides preserved as override layer
- [x] 1.3 `modules/desktop/syncthing.nix` — HM user service; pacman unit stopped + disabled on cutover; state at `~/.local/state/syncthing` preserved
- [x] 1.4 `modules/desktop/media.nix` — `programs.obs-studio.enable` (browserSupport off — cef-binary is ~1.95 GiB), inkscape, qbittorrent, vesktop
- [x] 1.5 `flake.nix` — vicinae flake input pinned (`inputs.nixpkgs.follows`); `flake-parts` nixpkgs-lib follows; `direnv-instant` nixpkgs follows
- [x] 1.6 Register `"portals"`, `"vicinae"`, `"syncthing"`, `"media"` in `hmAspects` (`modules/hosts/arch.nix`)
- [x] 1.7 `modules/secrets.nix` — `pkgs.age` added explicitly as safety belt (sops HM activation shells out to it)

## 2. Phase 2 — Browsers (lazy HM)

- [x] 2.1 `modules/apps/browser/firefox.nix` — `programs.firefox.enable = true`; `programs.firefox.package = pkgs.firefox`; profile migrated to XDG path `~/.config/mozilla/firefox/` via `stateVersion=26.11` bump (was 25.11)
- [x] 2.2 `modules/apps/browser/chromium.nix` — `programs.chromium.enable = true`; `programs.chromium.package = pkgs.chromium`; profile `~/.config/chromium` left untouched
- [x] 2.3 `modules/apps/browser/thunderbird.nix` — `programs.thunderbird.enable = true`; profile `~/.thunderbird` left untouched
- [x] 2.4 `modules/apps/browser/brave.nix` — `home.packages = [ pkgs.brave ]` (no HM module exists); `~/.config/BraveSoftware` stays imperative
- [x] 2.5 Register `"brave"`, `"chromium"`, `"firefox"`, `"thunderbird"` in `hmAspects` (`modules/hosts/arch.nix`)
- [x] 2.6 `git add -N` new aspect files for flake visibility
- [x] 2.7 `nix flake check --no-build --no-write-lock-file` passes
- [x] 2.8 Firefox profile migrated to XDG path (moved `~/.mozilla/firefox/*` → `~/.config/mozilla/firefox/`); leftover session-state files at old location cleaned; `~/.mozilla/native-messaging-hosts/` retained (HM-managed, hardcoded path)

## 3. Apply + Verify (Phase 2)

- [x] 3.1 `nh home switch .` — activates stateVersion=26.11; browsers resolve to `~/.nix-profile/bin/...`
- [x] 3.2 User confirms all four browsers launch with profile data intact
- [x] 3.3 `sudo pacman -Rns firefox chromium brave-bin thunderbird` — browser stack off pacman
- [~] 3.4 Drop the 4 stale fonts — **partial**: `ttf-bitstream-vera` removed; `ttf-dejavu` + `ttf-liberation` blocked by `onlyoffice-bin`; `noto-fonts` blocked by `plasma-integration` (KDE stack kept). Resolved: onlyoffice-bin will be removed in Phase 3 when libreoffice is migrated; noto-fonts waits on KDE stack removal or NixOS day.

## 4. Phase 3 — KDE keepers (next revision, not in this revision)

- [ ] 4.1 Audit KDE stack: which plasma apps are actually used (dolphin, okular, ark, gwenview) vs unused (haruna, kid3, krokiet, systemsettings)
- [ ] 4.2 Drop unused plasma apps via `pacman -Rns` (no Nix replacement needed for unused)
- [ ] 4.3 Drop `polkit-kde-agent` (noctalia's `shell.polkit_agent` is enabled)
- [ ] 4.4 Migrate `dolphin`, `okular`, `ark`, `gwenview` via `home.packages = [ pkgs.kdePackages.dolphin ... ]` — no dedicated HM modules exist
- [ ] 4.5 Resolve Qt platform-theme integration: ensure `QT_QPA_PLATFORMTHEME=qt6ct` (or similar) points at Nix store Qt; verify dolphin runs stylishly
- [ ] 4.6 `pacman -Rns plasma-workspace` (the last anchor on `xdg-desktop-portal-kde`)
- [ ] 4.7 Optionally drop `xdg-desktop-portal-kde` from pacman if portal stack no longer anchors it

## 5. Phase 4 — Decision items (deferred, separate changes)

- [ ] 5.1 Flatpak as long-term GUI layer (decide: keep `firefox`/`chromium` HM or move to flatpak; flatpak profile state at `~/.var/app/` carries over to NixOS unchanged)
- [ ] 5.2 System daemons (bluez, NetworkManager, dracut, snapper, nvidia) — NixOS-native, defer
- [ ] 5.3 Office apps (onlyoffice-bin, libreoffice, inkscape deep deps) — flatpak vs HM vs pacman-keep
- [ ] 5.4 Neovim config migration (extensive, not currently in Nix)
- [ ] 5.5 `accountsservice` + AUR keyrings (Arch-specific)

## 6. Validation

- [x] 6.1 `nix flake check --no-build --no-write-lock-file` passes (covers statix, deadnix, nixfmt, full eval of HM + system-manager configs)
- [x] 6.2 `openspec validate --strict` passes after OpenSpec change is complete
- [x] 6.3 User confirms acceptance: browsers launch from `~/.nix-profile/bin/...`; profiles 100% intact; pacman explicit count 274 → 267 (4 browsers + ttf-bitstream-vera removed; 3 fonts blocked by onlyoffice-bin/plasma-integration)

## 7. Phase 3a — Office + remaining GUI apps (this revision)

Bundles 13 leaves + drops 2 unused (seahorse, keepassxc) + drops onlyoffice-bin (font-anchor). Wireshark-qt/cli stay pacman (dumpcap/perms). sublime-merge + kvantum dropped from migration scope (kept on pacman for now or removed by user later).

### 7.1 — Single-package aspects

- [x] 7.1.1 `modules/apps/libreoffice.nix` — aspect `libreoffice`; `home.packages = [ pkgs.libreoffice-fresh ]`; user config at `~/.config/libreoffice/4/` left untouched
- [x] 7.1.2 `modules/apps/vscode.nix` — aspect `vscode`; `programs.vscode.{enable=true, package=pkgs.vscode-fhs}` (FHS variant for extension compat); existing `~/.config/Code/` untouched (lazy HM); `"vscode"` + `"code"` added to `allowUnfreePredicate` in `modules/nix.nix`
- [ ] 7.1.3 Drop `onlyoffice-bin` from pacman (sole anchor on `ttf-dejavu` + `ttf-liberation`)
- [ ] 7.1.4 Drop `seahorse` + `keepassxc` from pacman (unused per user)

### 7.2 — Bundled aspects (single `home.packages` list per aspect)

- [x] 7.2.1 `modules/apps/kde.nix` — aspect `kde-apps`; `home.packages` = `[ kdePackages.dolphin dolphin-plugins okular ark gwenview kdialog kdeconnect-kde ]` + top-level `pkgs.haruna` (top-level attr, not under kdePackages)
- [x] 7.2.2 `modules/apps/audio.nix` — aspect `audio`; `home.packages = [ pkgs.feishin pkgs.kid3 pkgs.easyeffects pkgs.qpwgraph ]`
- [x] 7.2.3 `modules/apps/util.nix` — aspect `util-apps`; `home.packages = [ pkgs.meld pkgs.puddletag pkgs.czkawka pkgs.gparted pkgs.smartcat pkgs.matugen ]`
  - **Deviation**: `appimagelauncher` dropped from this aspect — no nixpkgs equivalent exists. Either keep `appimagelauncher` on pacman, or replace with `pkgs.gearlever` / `pkgs.appimage-run` (different UX). Decision pending user.
  - **Deviation**: pacman `krokiet-bin` → `pkgs.czkawka` (Krokiet GUI ships inside czkawka; same binary functionality, different package name)
- [x] 7.2.4 Register `"libreoffice"`, `"vscode"`, `"kde-apps"`, `"audio"`, `"util-apps"` in `hmAspects` (`modules/hosts/arch.nix`)
- [x] 7.2.5 `git add -N` new aspect files for flake visibility

### 7.3 — Verify + apply

- [x] 7.3.1 `nix flake check --no-build --no-write-lock-file` passes
- [x] 7.3.2 `nh home switch .` - installs all migrated apps from Nix store
- [x] 7.3.3 Verify each app launches with existing config intact: vscode (`~/.config/Code`), libreoffice (`~/.config/libreoffice`), dolphin (`~/.config/dolphinrc`), kdeconnect, kid3 etc.
- [x] 7.3.4 Drop pacman duplicates (21 packages - appimagelauncher stays): `sudo pacman -Rns libreoffice-fresh visual-studio-code-bin kid3 kdeconnect haruna gwenview okular ark kdialog dolphin dolphin-plugins meld puddletag feishin-bin krokiet-bin easyeffects qpwgraph gparted smartcat matugen`
- [x] 7.3.5 Drop `seahorse` + `keepassxc` (unused) + `onlyoffice-bin` (font anchor): `sudo pacman -Rns seahorse keepassxc onlyoffice-bin`
- [x] 7.3.6 Drop the now-unblocked fonts: `sudo pacman -Rns ttf-dejavu ttf-liberation`
- [x] 7.3.7 Final pacman explicit count audit
- [x] 7.3.8 `fc-cache -f`; verify font resolution still correct
- [x] 7.3.9 `openspec validate --strict` passes

## 9. Phase 3c — Anchor drops (wireshark-qt + appimagelauncher + 22 orphan leaves)

Dropping the two Qt anchors unchains the entire Qt5 + Qt6 stacks. Plus 22 orphan leaf packages confirmed via full `pactree -r` traversal (4 parallel audit subagents). gmrender-resurrect-git dropped (unanchors gstreamer base cluster). accountsservice kept (anchored by libmalcontent).

### 9.1 — Anchor + cascade drops

- [x] 9.1.1 `sudo pacman -Rns wireshark-qt wireshark-cli` — drops wireshark entirely; tshark/dumpcap available via Nix devshell when needed (dumpcap perms need NixOS for setcap; therefore using `nix shell nixpkgs#wireshark` on-demand). **Alternative needed**: Nix devshell or NixOS `programs.wireshark.enable` at migration day.
- [x] 9.1.2 `sudo pacman -Rns appimagelauncher` — no nixpkgs equivalent. **Alternative needed**: `pkgs.appimage-run` (runtime, no integration) or `pkgs.gearlever` (GUI AppImage manager, different UX). Decision pending.
- [x] 9.1.3 Qt5 + Qt6 stacks cascade out automatically via `-s` flag (pacman resolves the dependency tree)

### 9.2 — Orphan leaf drops (22 packages)

- [x] 9.2.1 `sudo pacman -Rns libdvdcss dnsmasq bind nfs-utils xl2tpd modemmanager usb_modeswitch openresolv systembus-notify smartmontools iotop` — disabled daemons + orphan system tools (smartmontools/iotop already on Nix)
- [x] 9.2.2 `sudo pacman -Rns python-pip python-pipx python-pynvim python-defusedxml python-aiohttp-oauthlib` — python leaf packages (python interpreter stays, 559 revdeps)
- [x] 9.2.3 `sudo pacman -Rns luarocks r pkgfile rebuild-detector meson` — dev toolchain leaves (already on Nix where needed)
- [x] 9.2.4 `sudo pacman -Rns gmrender-resurrect-git` — DLNA renderer, unused; unanchors gstreamer base + codec cluster

### 9.3 — Post-cascade cleanup

- [ ] 9.3.1 `pacman -Qdtq | sudo pacman -Rns -` — catch any orphans the cascade missed
- [ ] 9.3.2 Final pacman explicit count audit
- [ ] 9.3.3 Verify Nix completeness: all shells + GUI apps resolve from `~/.nix-profile/bin/`
