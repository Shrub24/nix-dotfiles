# ponytail: install-day stub. On NixOS day run
#   nixos-generate-config --root /mnt
# then hand-edit this file down to minimal (fileSystems, boot.loader.systemd-boot).
# Minimal values below satisfy NixOS's `toplevel` assertions so the eval gate
# passes; they are NOT switchable hardware config.
{ ... }: {
  fileSystems."/" = {
    device = "/dev/root";
    fsType = "ext4";
  };
  boot.loader.systemd-boot.enable = true;
}
