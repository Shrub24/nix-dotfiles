{ ... }:
{
  environment.etc."ssh/ssh_config.d/20-nixbuild.net.conf" = {
    text = ''
      Host eu.nixbuild.net
        ControlMaster auto
        ControlPersist 600
        ControlPath /run/nixbuild-ssh-%C
        ServerAliveInterval 60
        ServerAliveCountMax 3
        StrictHostKeyChecking accept-new
        SendEnv NIXBUILDNET_ACCESS_TOKENS
        Compression no
        IPQoS throughput
        TCPKeepAlive no
    '';
    mode = "0644";
  };

  environment.etc."nix/nixbuild.net.env" = {
    source = "/home/saurabhj/.config/nix/nixbuild.net.env";
    mode = "symlink";
  };

  systemd.services.nix-daemon.serviceConfig.EnvironmentFile = [
    "-/etc/nix/nixbuild.net.env"
  ];
}
