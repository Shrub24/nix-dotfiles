_: {
  # Native module wraps dumpcap with cap_net_raw,cap_net_admin so capture works unprivileged.
  flake.modules.nixos.wireshark =
    { config, pkgs, ... }:
    {
      programs.wireshark = {
        enable = true;
        # Default is wireshark-cli; the GUI is the point.
        package = pkgs.wireshark;
      };

      users.users.${config.currentHost.primaryUser.name}.extraGroups = [ "wireshark" ];
    };
}
