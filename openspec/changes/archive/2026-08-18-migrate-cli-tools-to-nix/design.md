## Context

The host runs Arch with pacman-managed packages alongside a Nix flake-managed Home Manager profile. The HM `shell` module (`modules/shell/default.nix`) already installs many CLI tools that still have pacman duplicates; the `programs.fzf` option owns `fzf`. Moving to a NixOS host in the near future means each pacman package is one more thing to re-decide. The host's `sessionPath` already puts `~/.nix-profile/bin` before `/usr/bin`, so Nix-provided binaries win resolution — moving a binary from pacman to HM does not change which gets invoked.

The niri-wm "Important Software" reference confirms the portal stack needs `xdg-desktop-portal-gtk` (default fallback), `xdg-desktop-portal-gnome` (screencast), and `gnome-keyring` (Secret portal). These are currently pacman-owned; a future Phase 2 can move them to HM (already partially done for `xdg-desktop-portal-*` via `modules/desktop/portals.nix`). `gnome-keyring` is held back by `seahorse` (which itself is held back by user choice for now).

## Goals / Non-Goals

**Goals:**

- Drop pacman duplicates of tools the HM `shell` module already installs
- Migrate trivially-portable CLI tools (zero revdeps) to HM
- Move font packages to HM (16 packages out of pacman)
- Move `ghostty`, `pavucontrol`, `zathura`, `libinput` to HM (unblocks the `xdg-desktop-portal` / `gtk4` consolidation in a later phase)
- Document what is left in pacman and why (Phase 2 scope)

**Non-Goals:**

- Migrate system daemons (pipewire, bluez, NetworkManager, dracut, etc.) — NixOS-native, deferred
- Touch neovim config — user's nvim config is extensive and not in Nix
- Migrate KDE Plasma GUI apps (dolphin, okular, etc.) — kept; `plasma-workspace` is the only revdep of `xdg-desktop-portal-kde`
- Migrate flatpak — left in place per user direction
- Migrate large office/media apps (libreoffice, onlyoffice, inkscape) — decision pending
- Migrate systemd, kernel, nvidia, limine, snapper, dracut — system-level, NixOS-native

## Decisions

### D1: Add CLI tools to existing `dev-tools` module (one file), not per-tool modules

Decision: A single bulk edit to `modules/dev-tools/default.nix` extends `home.packages` with the 20+ new CLI tools.
Rationale: These are leaf, user-scope CLI binaries with no config files. Per-tool modules would be ceremony for files-of-one-line-each. Matches the existing `dev-tools/default.nix` pattern (zotero, posting, isd, etc. are one-liners in a flat package list).
Alternative: per-tool modules (`modules/dev-tools/btop.nix`, `modules/dev-tools/lazygit.nix`) — rejected as over-modularization for zero-config tools.

### D2: Fonts go in a new `modules/desktop/fonts.nix` aspect

Decision: Dedicated module under the `desktop/` subtree, registered as HM aspect `fonts`.
Rationale: Fonts are user-scope display assets, fitting with the desktop tree (noctalia, monique, niri, portals). A dedicated module keeps the font list auditable in one file. On NixOS, `fonts.packages` flips this to system scope natively (the module becomes a one-line lift).
Alternative: add to `home.packages` of `shell/default.nix` — rejected; fonts aren't shell tools, would muddy concerns.

### D3: ghostty, zathura, pavucontrol, libinput each get a one-file aspect

Decision: Per-tool aspect files under `modules/desktop/`:

- `modules/desktop/ghostty.nix` — `home.packages = [ pkgs.ghostty ]` (and `xdg.configFile."ghostty/config"` only if user's existing config exists)
- `modules/desktop/zathura.nix` — `programs.zathura.enable = true` + `programs.zathura.extraPackages = [ pkgs.zathuraPkgs.zathura_pdf_mupdf ]`
- `modules/desktop/pavucontrol.nix` — `home.packages = [ pkgs.pavucontrol ]`
- `modules/desktop/libinput.nix` — `home.packages = [ pkgs.libinput ]` (provides `libinput`, `libinput-debug-events`, etc.)
  Rationale: These are GUI/interactive tools with potential config (ghostty config is in `~/.config/ghostty/config`). Each is a leaf user-scope concern; per-tool modules follow the repo's existing aspect pattern (one file = one HM aspect). zathura needs the mupdf plugin; the HM module wires it explicitly.
  Alternative: inline all in `modules/desktop/default.nix` — rejected; facade default.nix files are not the repo's current pattern (the dendritic single-tree migration flattened facades into aspect files).

### D4: Dev toolchains (rustup, go, deno, helm, uv) — rely on mise

Decision: Do NOT add these to the HM profile. The `modules/dev-tools/mise.nix` module already declares the user's mise-managed versions (node, pnpm, bun; plus rust, go, python via mise). Removing the pacman copies of `go`, `rustup`, `deno`, `helm`, `uv` does not require any Nix-side change — mise provides them at `~/.local/share/mise/shims/`.
Rationale: The user explicitly manages tool versions via mise to switch between projects; pacman versions are ambient noise. mise already installs these (verify with `mise list`); pacman copies were shadowing.
Alternative: install via `home.packages` — rejected; would conflict with mise's shims.

### D5: Order `hmAspects` addition

Decision: Add `"fonts"`, `"ghostty"`, `"pavucontrol"`, `"zathura"`, `"libinput"` to `hmAspects` in `modules/hosts/arch.nix`, in alphabetical order near the existing `"portals"` entry.
Rationale: matches the existing alphabetical-sorting convention. Single source of truth for host composition.

### D6: Apply sequence needs TODOs to capture the pacman-removal handoff

Decision: Tasks include both the Nix-side add AND the pacman-removal step. The Nix side applies with `nh home switch`; the pacman removal uses `pacman -Rns <pkg>` (the `-s` removes unneeded deps, `-n` removes their config). Order: HM switch first (installation), verify binaries resolve via `which <tool>`, THEN pacman remove.
Rationale: Whichever order, do not remove pacman packages before HM install of the replacements or PATH resolution breaks for that tool intermediately.

### D7: Late-after-apply verification of one `/usr/bin/<tool>` absolute-path reference

Decision: After HM switch, grep for `/usr/bin/(btop|yazi|lazygit|...|ghostty|pavucontrol|zathura|libinput)` across the repo and any imperative shell scripts in `~/.config/` — if found, they need path-rewriting to either the bare binary name or `/nix/store/.../bin/<tool>` absolute.
Rationale: tools that may be invoked from absolute-path `/usr/bin/<x>` will still resolve to the pacman copy if it's installed, then break when pacman removes it. The user's `sessionPath` already puts `~/.nix-profile/bin` first, so bare-name invocations resolve correctly.

### D8: `xdg-desktop-portal-gnome` stays in pacman (for now)

Decision: Do not remove `xdg-desktop-portal-gnome` from pacman in this phase. It has zero pacman reverse deps (per `pacman -Qi`), but the HM-managed `modules/desktop/portals.nix` already declares it in `xdg.portal.extraPortals`. The pacman copy is redundant for the HM session but it doesn't hurt to leave it — it's small, well-cached, and removing it might affect some share/xdg-desktop-portal/portals fallback in pacman-space UIs.
Rationale: avoid scope creep; this is a system-side concern rather than user-scope, fits Phase 2 better.

## Risks / Trade-offs

- **`fzf` reverse dep `downgrade`** — pacman package `downgrade` depends on `fzf`. After removing pacman's `fzf`, `downgrade` (an AUR helper for package downgrades) may break. **Mitigation**: confirm `downgrade` uses bare `fzf` name (resolves via session PATH) before removal; if it uses `/usr/bin/fzf`, leave pacman's `fzf` in place.
- **`sd`/`fd`/`ripgrep` optional revdep `hwdetect`** — `hwdetect` is Arch-specific hardware detection. **Mitigation**: `hwdetect` will be removed entirely on NixOS migration; if it breaks, drop it from pacman alongside the tool removals.
- **`chafa` reverse dep `ueberzugpp`** — `ueberzugpp` (image preview) declares `chafa` as a hard dependency. **Mitigation**: check if `ueberzugpp` is still actively used; if not, drop alongside. If used, install `chafa` in both or leave the pacman copy.
- **`man-db` reverse dep `dex`** — `dex` (XDG autostart) depends on `man-db`. **Mitigation**: leave `man-db` in pacman — Nix-side man pages come via `man.manpages.enable` if needed later; `dex` is unused under niri anyway.
- **ghostty config drift** — if `~/.config/ghostty/config` exists imperatively, the HM module's `xdg.configFile."ghostty/config"` would clobber on activation. **Mitigation**: check for existing config; back up with `-b backup` switch.
- **PATH ordering** — moving `/usr/bin/btop` to `~/.nix-profile/bin/btop` shifts resolution to the Nix profile (already first in `sessionPath`). **Mitigation**: verify after switch with `which <tool>` before removing pacman copies.
- **font cache rebuild** — installing fonts via HM requires `fc-cache -f` to refresh the fontconfig cache. **Mitigation**: HM's `home.packages` runs the cache update in activation; no manual step.

## Migration Plan

1. **Build**: `nix flake check --no-build --no-write-lock-file` to confirm evaluation
1. **Switch**: `nh home switch .` — installs all new HM packages
1. **Verify PATH**: `which btop lazygit yazi ghostty pavucontrol zathura libinput` → all should resolve to `~/.nix-profile/bin/...`
1. **Verify fonts**: `fc-list | rg -i 'maplemono|noto|liberation' | head` → Nix-store paths
1. **Remove pacman copies** — three batches:
   - Batch 1 (already-installed dupes): `pacman -Rns bat duf procs bottom dust sd fd ripgrep jq chafa fzf`
   - Batch 2 (Phase 1 migrated CLI): `pacman -Rns btop gping hyperfine ncdu pv rsync tealdeer xh yazi lazygit lazydocker lazyjj jujutsu just uv eza exa glow entr git-delta git-filter-repo github-cli curlie go-task deno helm rustup go mold`
   - Batch 3 (Phase 1 GUI + fonts): `pacman -Rns ghostty ghostty-shell-integration ghostty-terminfo pavucontrol zathura zathura-pdf-mupdf libinput-tools gtk4-demos ttf-maplemono ttf-maplemono-nf ttf-firacode-nerd ttf-liberation noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-opensans ttf-dejavu ttf-bitstream-vera cantarell-fonts`
1. **Snapshot**: take a snapper btrfs snapshot before each batch for fast rollback
1. **Document Phase 2** in `openspec/changes/migrate-cli-tools-to-nix/design.md` (already in this doc above)

**Rollback**:

- HM: `nh home switch --rollback`
- pacman: `pacman -S <removed packages>` or restore from snapper snapshot

## Execution Results (2026-08-17)

Applied end-to-end. Pacman explicit package count: 322 → 274 (48 packages dropped).

**What landed in HM**: 6 new homeManager aspects under `modules/dev-tools/cli.nix` (23 CLI tools incl. `go`/`rustc`/`cargo`/`uv`) and `modules/desktop/{fonts,ghostty,zathura,pavucontrol,libinput}.nix`; all registered in `hmAspects` (`modules/hosts/arch.nix`).

**What stayed in pacman** (revdep-anchored, deferred to Phase 2): `ripgrep` (opencode-bin + kio-extras anchors), four fonts (`ttf-liberation`, `noto-fonts`, `ttf-dejavu`, `ttf-bitstream-vera` — browser/office/qt6-webengine chain), `xdg-desktop-portal-*` stack (browser/office anchors), `ttf-bitstream-vera` (browser stack). The session's `cliphist` removal cascaded `wl-clipboard` (restored via `modules/desktop/portals.nix`); `biber` and `markdownlint-cli2` deferred to per-project devshells.

**Toolchain decision**: `mise` retained — it owns node ecosystem only (`aube`/`bun`/`node`/`pnpm` + npm tools). `go`/`rustc`/`cargo`/`uv` moved to HM (fixed Nix versions, no rustup toolchain-switching). `deno`/`helm`/`mold` dropped entirely (on-demand via `nix profile install`).

**Phase 2 scope deferred** (tracked separately, to be opened as `migrate-browsers-to-nix`): browsers, KDE plasma-workspace + GUI apps, xdg-desktop-portal-kde, flatpak, system daemons, large office/media apps.
