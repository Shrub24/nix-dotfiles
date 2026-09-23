vm-desktop:
    #!/usr/bin/env fish
    nix build .#checks.x86_64-linux.vm-desktop.driverInteractive
    if not set -q WAYLAND_DISPLAY
      echo "vm-desktop requires a Wayland session" >&2
      exit 1
    end
    begin
      echo 'start_all()'
      cat
    end | env -u DISPLAY SDL_VIDEODRIVER=wayland QEMU_OPTS="-display sdl,gl=on" ./result/bin/nixos-test-driver

# Update all nvfetcher sources (pkgs/_sources).
nvfetcher:
    nix run .#nvfetcher-update

# Update one nvfetcher source, leaving the rest pinned.
nvfetcher-one pkg:
    nix run .#nvfetcher-update -- --filter '^{{pkg}}$'

# Point the nix-fleet input at a local checkout (default ../nix-fleet) so a
# dotfiles change can be tested against a coordinated nix-fleet change.
fleet-check fleet_dir=env("NIX_FLEET_DIR", "../nix-fleet"):
    nix flake check --no-build --no-write-lock-file --override-input nix-fleet path:{{fleet_dir}}
