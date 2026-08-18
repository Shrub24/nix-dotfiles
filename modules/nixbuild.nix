{ inputs, ... }: {
  flake.modules.systemManager.nixbuild =
    {
      config,
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

  flake.modules.nixos.nixbuild =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = {
        defaultSopsFile = ../secrets/nixbuild.yaml;
        age = {
          keyFile = "/var/lib/sops-nix/key.txt";
          # Keep generateKey = false for parity with the systemManager aspect;
          # user can flip when ready to rotate / use a pre-generated key (works
          # on NixOS too). NixOS already has a `keys` group, so the Arch-only
          # users.groups.keys = {} workaround is dropped.
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

      # NixOS ships nix-daemon units natively (nix.enable = true from the
      # `nixos.nix` aspect) - no systemd.packages = [ pkgs.nix ] needed, and no
      # systemd.sockets.nix-daemon.wantedBy (NixOS enables the socket by default
      # when nix.daemon is on). Just wire the sops EnvironmentFile dependency.
      systemd.services.nix-daemon = {
        after = [ "sops-install-secrets.service" ];
        wants = [ "sops-install-secrets.service" ];
        serviceConfig.EnvironmentFile = [ "-/run/secrets/rendered/nixbuild.net.env" ];
      };
    }

  ;
}
