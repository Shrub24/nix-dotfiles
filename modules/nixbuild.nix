_: {
  flake.modules.systemManager.nixbuild =
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = {
        defaultSopsFile = ../secrets/nixbuild.yaml;
        useSystemdActivation = true;
        age = {
          keyFile = "/var/lib/sops-nix/key.txt";
          generateKey = false;
        };

        secrets.NIXBUILDNET_ACCESS_TOKENS = {
          format = "yaml";
          key = "nixbuildnet_access_token";
          restartUnits = [ "nix-daemon.service" ];
        };

        templates."nixbuild.net.env" = {
          content = ''
            NIXBUILDNET_ACCESS_TOKENS=${config.sops.placeholder.NIXBUILDNET_ACCESS_TOKENS}
          '';
        };
      };

      # Arch has no `keys` group (NixOS default for sops secret ownership);
      # sops-install-secrets exits 1 without it.
      users.groups.keys = { };

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

      systemd.packages = [ pkgs.nix ];

      systemd.services.nix-daemon = {
        after = [ "sops-install-secrets.service" ];
        wants = [ "sops-install-secrets.service" ];
        serviceConfig.EnvironmentFile = [ "-/run/secrets/rendered/nixbuild.net.env" ];
      };

      systemd.sockets.nix-daemon = {
        wantedBy = [ "sockets.target" ];
      };
    }

  ;
}
