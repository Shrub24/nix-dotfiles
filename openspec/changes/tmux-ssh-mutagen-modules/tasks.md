## 1. Module structure

- [x] 1.1 Create `modules/home/remote/` directory with `default.nix`
- [x] 1.2 Create `modules/home/tmux.nix`
- [x] 1.3 Create `modules/home/remote/ssh.nix`
- [x] 1.4 Create `modules/home/remote/mutagen.nix`
- [x] 1.5 Add `./home/tmux.nix` and `./home/remote` to `modules/default.nix`

## 2. Tmux config

- [x] 2.1 Populate `modules/home/tmux.nix` with `programs.tmux` — enable, basic settings, sensible defaults for persistent remote sessions

## 3. SSH client config

- [x] 3.1 Populate `modules/home/remote/ssh.nix` with `programs.ssh` — enable, global client defaults, no host-specific blocks, no known_hosts/authorized_keys/private key material

## 4. Mutagen

- [x] 4.1 Populate `modules/home/remote/mutagen.nix` — `home.packages = [ pkgs.mutagen ]`

## 5. Host config wiring

- [x] 5.1 Enable `programs.tmux` in `hosts/arch/home.nix` (enabled directly in module)

## 6. Validation

- [x] 6.1 Run `nh home build` and confirm the build succeeds
