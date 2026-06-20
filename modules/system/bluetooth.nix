{ config, pkgs, ... }:
{

  systemd.services.rfkill-unblock-bluetooth = {
    description = "Unblock Bluetooth radio after boot";
    after = [ "bluetooth.service" "sysinit.target" ];
    wants = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
      RemainAfterExit = true;
    };
  };

}
