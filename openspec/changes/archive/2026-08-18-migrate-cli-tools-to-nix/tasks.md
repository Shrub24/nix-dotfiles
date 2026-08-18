## 1. Add New HM Packages (Phase 1 — Nix side)

- [x] 1.1 Extend `modules/dev-tools/default.nix` `home.packages` with CLI utilities: `btop`, `gping`, `hyperfine`, `ncdu`, `pv`, `rsync`, `tealdeer`, `xh`, `yazi`, `glow`, `entr`, `git-delta`, `git-filter-repo`, `github-cli`, `curlie`, `eza`, `exa`, `lazygit`, `lazydocker`, `lazyjj`, `jujutsu`, `just`, `go-task`, `mold`
- [x] 1.2 Create `modules/desktop/fonts.nix` aspect — register HM aspect `fonts` with `home.packages = [ maplemono maplemono-nerd firacode-nerd-font liberation_ttf noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra opensans dejavu_fonts bitstream-vera-fonts cantarell-fonts ]`
- [x] 1.3 Check existing `~/.config/ghostty/config`; if present, back up to `~/.config/ghostty/config.bak-pre-nix`
- [x] 1.4 Create `modules/desktop/ghostty.nix` aspect — `programs.ghostty.enable = true` if HM module exists, else `home.packages = [ pkgs.ghostty ]` + `xdg.configFile."ghostty/config"` sourced from backed-up config
- [x] 1.5 Create `modules/desktop/zathura.nix` aspect — `programs.zathura.enable = true`, `programs.zathura.extraPackages = [ pkgs.zathuraPkgs.zathura_pdf_mupdf ]`, optionally `programs.zathura.options` for existing prefs
- [x] 1.6 Create `modules/desktop/pavucontrol.nix` aspect — `home.packages = [ pkgs.pavucontrol ]`
- [x] 1.7 Create `modules/desktop/libinput.nix` aspect — `home.packages = [ pkgs.libinput ]` (provides `libinput`, `libinput-debug-events`)
- [x] 1.8 Add new aspects (`"fonts"`, `"ghostty"`, `"pavucontrol"`, `"libinput"`, `"zathura"`) to `hmAspects` in `modules/hosts/arch.nix`, alphabetical near `"portals"`
- [x] 1.9 Stage new files with `git add -N`; run `nix flake check --no-build --no-write-lock-file` — verify all checks pass

## 2. Pre-Apply Verification (Nix side only)

- [x] 2.1 `nh home build .` — full build succeeds, no eval errors
- [x] 2.2 Confirm `programs.fzf` already owns fzf in `shell/default.nix` (no new package needed); only pacman `fzf` will be removed
- [x] 2.3 Dry-run check: `nix build --dry-run .#homeConfigurations.saurabhj.activationPackage 2>&1 | rg 'will be'` — confirm fetch-heavy (Hydra cache), few local builds

## 3. Apply Nix Side

- [x] 3.1 `nh home switch -b backup .` — back up any clobbered files; verify clean activation
- [x] 3.2 Verify PATH resolution: `which btop lazygit yazi ghostty pavucontrol zathura libinput fc-list` — all resolve to `~/.nix-profile/bin/...` or Nix store
- [x] 3.3 Verify fonts: `fc-list | rg -i 'maplemono|noto-sans|liberation' | head` — fonts from `/nix/store/...`
- [x] 3.4 Verify ghostty config preserved: `ghostty +show-config 2>&1 | head` or visible in launch
- [x] 3.5 Grep for absolute `/usr/bin/<tool>` references: `rg '/usr/bin/(btop|lazygit|yazi|ghostty|pavucontrol|zathura|libinput|fd|jq|bat|sd|duf|dust|procs)' modules/ ~/.config/` — fix any that exist (rewrite to bare name or absolute `/nix/store/...`)

## 4. Remove Pacman Duplicates (Batch 1 — already-installed HM dupes)

- [x] 4.1 Verify `downgrade` package's `fzf` reference resolves via session PATH (not `/usr/bin/fzf`) — `rg 'fzf' $(which downgrade) 2>/dev/null || true`
- [x] 4.2 `sudo pacman -Rns bat duf procs dust sd fd ripgrep jq chafa fzf downgrade hwdetect ueberzugpp` — accepted orphan-removal; ripgrep stayed (opencode-bin+kio-extras anchors); 11 packages dropped
- [x] 4.3 Confirm `which bat fd jq ripgrep fzf` still resolves to `~/.nix-profile/bin/...` after removal

## 5. Remove Pacman CLI Tools (Batch 2 — Phase 1 migrated)

- [x] 5.1 Take snapper btrfs snapshot: `sudo snapper -c root create -d "pre-nix-cli-migration"`
- [x] 5.2 `sudo pacman -Rns btop gping hyperfine ncdu pv rsync tealdeer xh yazi lazygit lazydocker lazyjj jujutsu just uv eza glow entr git-delta git-filter-repo github-cli curlie go-task deno helm rustup go mold` — deno/helm dropped entirely (no replacement); go/rustc/cargo/uv moved to HM (`modules/dev-tools/cli.nix`)
- [x] 5.3 Confirm `mise list` shows node, pnpm, bun (mise keeps owning node ecosystem only)
- [x] 5.4 Confirm `which go rustc cargo uv` resolves to `~/.nix-profile/bin/...` (Nix-managed, not mise)

## 6. Remove Pacman GUI Apps + Fonts (Batch 3 — Phase 1 GUI)

- [x] 6.1 `sudo pacman -Rns gtk4-demos` — pure demo, no replacement
- [x] 6.2 `sudo pacman -Rns ghostty ghostty-shell-integration ghostty-terminfo` — ghostty now from Nix
- [x] 6.3 `sudo pacman -Rns pavucontrol zathura zathura-pdf-mupdf` — now from Nix
- [x] 6.4 `sudo pacman -Rns libinput-tools` — CLI tools now from `pkgs.libinput`
- [x] 6.5 `sudo pacman -Rns ttf-maplemono ttf-maplemono-nf ttf-firacode-nerd noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-opensans cantarell-fonts` — fonts now from HM (ttf-liberation/noto-fonts/ttf-dejavu/ttf-bitstream-vera stayed: hard revdeps in browser/office/KDE stack)
- [x] 6.6 Run `fc-cache -f` (HM should do this automatically but confirm)
- [x] 6.7 Verify `xdg-desktop-portal-gtk` still installed (kept for portals stack)

## 7. Documentation

- [x] 7.1 Update `openspec/changes/migrate-cli-tools-to-nix/design.md` with execution results: list what was actually removed vs. kept-back; note any unexpected revdeps encountered
- [x] 7.2 Update `ARCHITECTURE.md` "Durable Decisions" section: note that fonts, ghostty, zathura, pavucontrol, libinput, and the dev CLI tools are now HM-managed; flatpak, KDE apps, system daemons remain pacman-pending NixOS migration
- [x] 7.3 Create `openspec/changes/migrate-cli-tools-to-nix-phase-2/` proposal stub documenting Phase 2 scope (KDE GUI decision, system daemons, large office apps, flatpak, xdg-desktop-portal-\* consolidation, accountsservice removal)

## 8. Validation

- [x] 8.1 `nix flake check --no-build --no-write-lock-file` — passes
- [x] 8.2 All removed CLI tools resolve via `~/.nix-profile/bin/` or mise shims: `which btop lazygit yazi ghostty pavucontrol zathura libinput bat fd jq go rustc cargo uv` — all `~/.nix-profile/bin/...`
- [x] 8.3 No broken pacman dependency tree: `pacman -Dk` succeeds, packages removed cleanly
- [x] 8.4 GUI apps launch: `ghostty`, `pavucontrol`, `zathura` — all resolved via `~/.nix-profile/bin/` (user verified)
- [x] 8.5 Fonts visible: Maple Mono NF from `~/.nix-profile/share/fonts/truetype/`; Liberation Serif from `/usr/share/fonts/liberation/` (pacman copy stays as revdep of browser stack)
- [x] 8.6 User confirms acceptance: 322 → 274 explicit pacman packages; tools behave identically to pre-migration
