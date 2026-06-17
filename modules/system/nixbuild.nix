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
    '';
    mode = "0644";
  };

  environment.etc."nix/nixbuild.net.env.example" = {
    text = ''
      NIXBUILDNET_ACCESS_TOKENS=token-1 token-2
    '';
    mode = "0644";
  };

  systemd.services.nix-daemon.serviceConfig.EnvironmentFile = [
    "-/etc/nix/nixbuild.net.env"
  ];
}
