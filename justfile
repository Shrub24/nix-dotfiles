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
