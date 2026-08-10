## 1. OpenSpec And Packaging Setup

- [x] 1.1 Create `pkgs/snip/default.nix` using `buildGoModule` with a pinned upstream `snip` release
- [x] 1.2 Register `snip` in the flake overlay and remove the `tokf` overlay entry
- [x] 1.3 Remove the obsolete `pkgs/tokf` package directory once `snip` is wired in

## 2. Home Manager And OpenCode Integration

- [x] 2.1 Replace `tokf` with `snip` in `modules/home/agents/tools.nix`
- [x] 2.2 Add `opencode-snip` to `apps/opencode/opencode.jsonc`

## 3. Documentation And Verification

- [x] 3.1 Update `ARCHITECTURE.md` and `STRUCTURE.md` to reflect `snip` instead of `tokf`
- [x] 3.2 Verify `nix eval .#homeConfigurations.saurabhj.activationPackage.drvPath`
- [x] 3.3 Verify `nix build .#homeConfigurations.saurabhj.activationPackage --no-link`
- [x] 3.4 Verify the packaged CLI runs via `snip --version` from the built environment
