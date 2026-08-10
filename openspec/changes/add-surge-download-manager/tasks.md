## 1. Package Integration

- [ ] 1.1 Add and lock the Surge flake input at release 0.11.2 with nixpkgs following the project input
- [ ] 1.2 Add `pkgs/surge/default.nix` to correct the upstream package version and linker metadata
- [ ] 1.3 Register `pkgs.surge` in the overlay and install it from `modules/home/dev-tools/default.nix`

## 2. Verification and Documentation

- [ ] 2.1 Build and switch Home Manager, verify `surge --version`, and confirm no Surge user service is enabled
- [ ] 2.2 Update architecture documentation and run strict OpenSpec validation
