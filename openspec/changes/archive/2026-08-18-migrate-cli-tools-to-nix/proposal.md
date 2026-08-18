## Why

The host currently maintains ~322 explicit pacman packages alongside a Home Manager profile of 147 binaries. Many tools exist in both trees simultaneously; others are CLI leaves trivially installable via Nix. This duplication will be painful to carry across the NixOS migration. Phase 1 thins the pacman tree by migrating redundant and trivially-portable user-scope packages to HM, leaving system daemons, the full KDE GUI app set, flatpak, and large GUI apps (libreoffice/onlyoffice/inkscape) for a later Phase 2 decision.

## What Changes

### Migrated to Home Manager

**Already-installed HM tools (drop pacman duplicates)** — the HM `shell` module already installs these; pacman copies are pure redundancy:

- `bat`, `duf`, `procs`, `bottom`/`btm`, `dust`, `sd`, `fd`, `ripgrep`, `jq`, `chafa`
- Leave `poppler-utils`, `mediainfo`, `pistol`, `man-db`, `shared-mime-info` in pacman — they have Arch-side reverse deps (libreoffice, cups, ueberzugpp, dex)

**New HM additions** (pacman → Nix):

- **CLI utilities**: `btop`, `gping`, `hyperfine`, `ncdu`, `pv`, `rsync`, `tealdeer`, `xh`, `yazi`, `glow`, `entr`, `git-delta`, `git-filter-repo`, `github-cli`, `curlie`, `eza`, `exa` (de-dupe with eza)
- **Lazy tools**: `lazygit`, `lazydocker`, `lazyjj`
- **VCS/build**: `jujutsu`, `just`, `go-task`
- **Dev toolchains** — already partially managed by `mise` (`modules/dev-tools/mise.nix`); pacman copies of `go`, `rustup`, `deno`, `helm`, `uv` become redundant
- **GUI consumers** of `xdg-desktop-portal` / `gtk4` chain (unblocks portal consolidation):
  - `ghostty` (user confirmed backup-only; no `ghostty-shell-integration` / `ghostty-terminfo` needed)
  - `pavucontrol`, `zathura` (with `zathura-pdf-mupdf`), `libinput` (CLI tools via `pkgs.libinput`)
- **Fonts**: `maplemono`, `maplemono-nerd`, `firacode-nerd`, `liberation_ttf`, `noto-fonts`, `noto-fonts-cjk`, `noto-fonts-emoji`, `noto-fonts-extra`, `open-sans`, `dejavu_fonts`, `bitstream-vera`, `cantarell-fonts`

### Removed (no replacement)

- `gtk4-demos` — demos, never used
- `bat`/`duf`/`procs`/`dust`/`fd`/`jq`/`sd`/`ripgrep`/`chafa` pacman copies — duplicated by HM `shell` module
- `fzf` pacman copy — HM `programs.fzf.enable = true` in the shell module already provides it

### Explicitly left for Phase 2 (documented in design.md)

- **flatpak** — left in pacman; revisited at NixOS migration
- **KDE GUI apps** (dolphin, okular, kdialog, ark, gwenview, systemsettings, kdeconnect, plasma-workspace, plasma-integration) — kept in pacman; user wants GUI doc/media viewers; plasma-workspace is `xdg-desktop-portal-kde`'s only revdep
- **polkit-kde-agent** — thinnable but Noctalia has its own; left for now per user direction
- **System daemons** (pipewire stack, bluez, NetworkManager, dracut, plymouth, snapper, nvidia, linux kernel) — NixOS-native, not worth porting via system-manager
- **Large GUI apps** (libreoffice-fresh, onlyoffice-bin, inkscape) — decision pending; user not yet decided
- **neovim** — user config is extensive and not yet in Nix; explicitly out of scope
- **Accountsservice, appimagelauncher, archlinuxcn-keyring, endeavouros-keyring** — Arch-specific, removed on NixOS install

## Capabilities

### New Capabilities

- (none)

### Modified Capabilities

- (none)

This change is a pure refactor with no observable behavior change: existing tools continue to be on PATH and behave identically. Tooling moves from pacman-owned `/usr/bin/<tool>` to Nix-store-symlinked `~/.nix-profile/bin/<tool>`. Per OpenSpec rule, no spec-level requirement changes — `skip_specs: true` is set in `.openspec.yaml`.

## Impact

- **Files**:

  - `modules/dev-tools/default.nix` — add CLI utility, VCS, lazy, and dev toolchain packages
  - `modules/dev-tools/languages.nix` — possibly extend (if dev toolchains move here explicitly rather than relying on `mise`)
  - `modules/dev-tools/mise.nix` — explicit comment about pacman row removal (mise already manages)
  - `modules/shell/default.nix` — add `bottom` (already has btop alias), confirm `programs.fzf` owns fzf
  - New `modules/desktop/fonts.nix` — font packages via `home.packages`
  - New `modules/desktop/ghostty.nix` — ghostty + optionally `xdg.configFile."ghostty/config"`
  - New `modules/desktop/zathura.nix` — `programs.zathura` + pdf-mupdf plugin
  - New `modules/desktop/pavucontrol.nix` — `home.packages`
  - New `modules/desktop/libinput.nix` — `home.packages = [ pkgs.libinput ]` (CLI tools only)
  - `modules/hosts/arch/_home.nix` or `modules/desktop/default.nix` — if a desktop facade exists
  - `modules/hosts/arch.nix` — `hmAspects` list updates

- **Host packages removed**: ~50+ pacman packages drop after HM switch (CLI dupes, fonts, GUI consumers)

- **Risk**: tool PATH changes when binaries move from `/usr/bin` to `~/.nix-profile/bin`. The user's `sessionPath` already includes `~/.nix-profile/bin` first, so resolution priority is unchanged. Some absolute-path `/usr/bin/<tool>` references in shell scripts or Noctalia widgets could break — verify before applying each family.

- **Rollback**: HM switchrolls back on `nh home switch --rollback`; pacman removals recovered via `pacman -S <pkg>` or system snapshot (snapper) before applying.
