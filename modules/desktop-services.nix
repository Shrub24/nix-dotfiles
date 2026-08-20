_: {
  flake.modules.nixos.desktop-services = { ... }: {
    services.gvfs.enable = true;
    services.gnome.gnome-keyring.enable = true;
    services.accounts-daemon.enable = true;
    services.udisks2.enable = true;
    services.printing.enable = true;
    hardware.openrazer = {
      enable = true;
      users = [ "saurabhj" ];
    };
    services.logrotate.enable = true;
  };
}
