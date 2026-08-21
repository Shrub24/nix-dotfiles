{
  config,
  ...
}:
let
  # Typed primary-user topology read at the flake-parts level; closed over into
  # the NixOS desktop services (B11).
  primaryUser = config.topology.hosts.arch.primaryUser;
in
{
  flake.modules.nixos.desktop-services = { ... }: {
    services.gvfs.enable = true;
    services.gnome.gnome-keyring.enable = true;
    services.accounts-daemon.enable = true;
    services.udisks2.enable = true;
    services.printing.enable = true;
    services.fwupd.enable = true;
    hardware.openrazer = {
      enable = true;
      users = [ primaryUser.name ];
    };
    services.logrotate.enable = true;
  };
}
