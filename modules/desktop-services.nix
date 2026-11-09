_: {
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
      # ZMK boards (nice!nano, 1d50:615e): keypeek speaks ZMK Studio RPC over the
      # board's USB serial and HID. The board's BLE identity has no USB vendor or
      # product, so access to it is matched by modalias and comes with keypeek's
      # own packaged rule, which the keypeek aspect installs.
      services.udev.extraRules = ''
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="615e", MODE:="0666"
        KERNEL=="hidraw*", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="615e", MODE:="0666"
        KERNEL=="ttyACM*", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="615e", MODE:="0666"
      '';
      services.logrotate.enable = true;
    };
}
