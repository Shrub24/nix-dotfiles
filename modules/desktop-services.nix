_:
{
  flake.modules.nixos.desktop-services =
    { config, ... }:
    {
      services.gvfs.enable = true;
      services.gnome.gnome-keyring.enable = true;
      services.accounts-daemon.enable = true;
      services.udisks2.enable = true;
      services.printing.enable = true;
      services.fwupd.enable = true;
      hardware.openrazer = {
        enable = true;
        users = [ config.currentHost.primaryUser.name ];
      };
      services.logrotate.enable = true;
    };
}
