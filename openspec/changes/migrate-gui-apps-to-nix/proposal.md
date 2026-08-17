## Why

With the CLI-tools migration landed (archive/2026-08-17-migrate-cli-tools-to-nix), the remaining pacman surface is dominated by GUI apps: browsers, the KDE application stack, and large media/office hunks. Each retained pacman package is one more thing to re-decide at NixOS migration time, and several of them still anchor the four stale font packages (`ttf-liberation`, `noto-fonts`, `ttf-dejavu`, `ttf-bitstream-vera`) that we cannot drop until the browser/office/qt6-webengine dep chain is broken.

## What

Build a single umbrella change for the GUI-apps migration, with explicit phases:

- **Phase 1 — Already applied**: vicinae 0.26.2 (upstream HM module, `settings` + GUI-owned `settings.json` override layer), xdg-desktop-portal stack (`modules/desktop/portals.nix` — gtk/gnome/wlr/kde portals + NixOS-native session env via `home.sessionVariables`), syncthing HM service cutover (pacman user unit → HM systemd unit; state preserved) at `modules/syncthing.nix`, and media apps (`modules/apps/media.nix` — obs-studio with `browserSupport = false`, inkscape, qbittorrent, vesktop). Also relocates `ghostty.nix` from `modules/desktop/` to `modules/shell/` (matches wezterm/tmux terminal pattern) and splits user GUI apps from `modules/desktop/` into a new `modules/apps/` tree with `modules/apps/browser/` subfolder.
- **Phase 2 — Browsers (this revision)**: lazy-HM enablement for firefox, chromium, thunderbird (HM modules, profiles at `~/.mozilla` / `~/.config/chromium` / `~/.thunderbird` left untouched) and `pkgs.brave` package install (no HM module exists; `~/.config/BraveSoftware` stays imperative). Closes the four stale-font revdep chain.
- **Phase 3 — KDE keepers** (next revision): drop unused plasma apps (`haruna`, `kid3`, `krokiet`, `systemsettings`, `polkit-kde-agent` — noctalia owns polkit) + migrate keepers (`dolphin`, `okular`, `ark`, `gwenview`) via `home.packages` from `pkgs.kdePackages.*`. Qt platform-theme integration is the friction point and will be addressed in that revision.
- **Phase 4 — Decisions** (separate): flatpak as long-term GUI layer, system daemons (bluez, NetworkManager, dracut, snapper, nvidia, pipewire — NixOS-native), large office/media apps (onlyoffice, libreoffice, inkscape, gimp), neovim config migration, accountsservice + AUR keyrings.

## Out of scope

System daemons, kernel, nvidia, limine, dracut, snapper, and anything requiring NixOS-level modules — those defer to the actual NixOS migration. Neovim config (extensive, not in Nix). The meta-package `plasma` and `plasma5support` are already gone; the rest of the KDE stack is in scope for Phase 3.

## Consequences

- 4 + 4 new HM aspects (portals/vicinae/syncthing/media from Phase 1 already wired; brave/chromium/firefox/thunderbird from Phase 2 added in this revision) registered in `hmAspects` (`modules/hosts/arch.nix`).
- `flake.nix` pins the vicinae flake input (with `nixpkgs.follows`) and wires `flake-parts` + `direnv-instant` follows to nixpkgs — removing two independent nixpkgs indirections from the lockfile.
- Browser profiles stay exactly where they are; only the binary moves to `/nix/store`. On NixOS day, the same HM modules carry over unchanged.
- `xdg-desktop-portal-*` pacman packages will become removable once browser and office stacks are off pacman (Phase 2 + Phase 3 closure).
