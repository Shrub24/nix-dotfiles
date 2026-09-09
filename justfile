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

# Refresh the pinned models.dev registry hash (pkgs/models-dev/default.nix).
models-dev:
    #!/usr/bin/env bash
    set -euo pipefail
    hash=$(nix-prefetch-url --type sha256 https://models.dev/models.json)
    sri=$(nix hash convert --hash-algo sha256 --to sri "$hash")
    sed -i -E "s|hash = \"sha256-[^\"]*\";|hash = \"$sri\";|" pkgs/models-dev/default.nix
    echo "models-dev pinned to $sri"
