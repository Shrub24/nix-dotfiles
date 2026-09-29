_: {
  # Native module rather than a hand-setcap'd package: programs.wireshark
  # creates the `wireshark` group and wraps dumpcap with
  # cap_net_raw,cap_net_admin for that group, so capture works unprivileged and
  # survives a package bump.
  flake.modules.nixos.wireshark =
    { config, pkgs, ... }:
    {
      programs.wireshark = {
        enable = true;
        # Upstream's default is wireshark-cli; the GUI is the point here.
        package = pkgs.wireshark;
      };

      users.users.${config.currentHost.primaryUser.name}.extraGroups = [ "wireshark" ];
    };
}
