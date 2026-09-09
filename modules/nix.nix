{
  config,
  ...
}:
let
  primaryUser = config.topology.hosts.arch.primaryUser;
  system = config.topology.hosts.arch.system;
  # systemManager lacks nix.buildMachines (#466); renders into /etc/nix/machines instead.
  homeForgeBuilder = {
    hostName = "home-forge";
    sshUser = "dev";
    sshKey = "/root/.ssh/nix-remote";
    protocol = "ssh-ng";
    inherit system;
    maxJobs = 2;
    speedFactor = 2;
    supportedFeatures = [
      "big-parallel"
      "kvm"
      "nixos-test"
    ];
  };
  homeForgeMachinesLine =
    let
      inherit (homeForgeBuilder)
        protocol
        sshUser
        hostName
        system
        sshKey
        maxJobs
        speedFactor
        supportedFeatures
        ;
    in
    "${protocol}://${sshUser}@${hostName} ${system} ${sshKey} ${toString maxJobs} ${toString speedFactor} ${builtins.concatStringsSep "," supportedFeatures}";
in
{
  flake.modules.homeManager.nix =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      # Nix owns its access-tokens template (cross-module placeholder from credentials).
      sops.templates."nix-access-tokens" = {
        path = "${config.home.homeDirectory}/.config/nix/access-tokens.conf";
        content = "access-tokens = github.com=${config.sops.placeholder.GITHUB_PAT}\n";
      };

      home.packages = with pkgs; [
        nh
        nixd
        nvd
        nix-init
        statix
        deadnix
        nixfmt
        nix-output-monitor
        nix-index
        nix-tree
        manix
        envfs
        nix-ld
        nix-fast-build
        nix-update
        niks3-hook
        comma
        nix-your-shell
        tokei
        nix-search-tv-fzf
      ];

      programs = {
        nix-init = {
          enable = true;
          settings = {
            nixpkgs = "builtins.getFlake \"nixpkgs\"";
          };
        };

        nix-index = {
          enable = true;
        };

        nix-search-tv = {
          enable = true;
        };

        nix-your-shell = {
          enable = true;
          enableZshIntegration = true;
        };
      };

      nix.package = lib.mkDefault pkgs.nix;

      nix.extraOptions = ''
        !include ${config.sops.templates."nix-access-tokens".path}
      '';

      systemd.user.services.nh-clean = {
        Unit = {
          Description = "nh clean all — periodic Nix store cleanup";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${lib.getExe pkgs.nh} clean all --keep-since 7d";
        };
      };

      systemd.user.timers.nh-clean = {
        Unit = {
          Description = "Weekly nh clean all timer";
        };
        Timer = {
          OnCalendar = "weekly";
          Persistent = true;
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    }

  ;

  flake.modules.systemManager.nix =
    {
      pkgs,
      lib,
      ...
    }:
    let
      # niks3's user runtime socket path uses the topology UID (B11).
      inherit (primaryUser) uid;

      niks3UploadHook = pkgs.writeShellScriptBin "niks3-upload-hook" ''
        exec ${lib.getExe' pkgs.niks3-hook "niks3-hook"} send --socket /run/user/${toString uid}/niks3-upload-to-cache.sock
      '';
    in
    {
      nix.enable = true;

      environment.etc."nix/machines" = {
        text = homeForgeMachinesLine + "\n";
        mode = "0644";
      };

      nix.settings = {
        "trusted-users" = [
          "root"
          primaryUser.name
        ];
        "extra-substituters" = [
          "https://nix-community.cachix.org"
          "https://cache.numtide.com"
          "https://cache.shrublab.xyz"
        ];
        "trusted-substituters" = [
          "ssh-ng://eu.nixbuild.net"
        ];
        "extra-trusted-public-keys" = [
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nix-cache-1:FW0bJll9BP5ch0mHI+bXOImcD0RKLrH117WfQC+CU4A="
          "nixbuild.net/HWWKWC-1:dnSfpPDHQN/U9wexkK6r3GTaYrwqNwKS70SNGXistKg="
        ];
        "experimental-features" = [
          "nix-command"
          "flakes"
        ];
        "auto-optimise-store" = true;
        "always-allow-substitutes" = true;
        "builders-use-substitutes" = true;
        "builders" = "@/etc/nix/machines";
        "max-jobs" = "auto";
        "nix-path" = "nixpkgs=flake:nixpkgs";
        "keep-derivations" = true;
        "warn-dirty" = false;
        "accept-flake-config" = true;
        "download-buffer-size" = 268435456;
        "http-connections" = 64;
        "max-substitution-jobs" = 16;
        "post-build-hook" = lib.getExe niks3UploadHook;
      };

      environment.etc."profile.d/nix-path.sh".text = ''
        export NIX_PATH=nixpkgs=flake:nixpkgs
      '';
    }

  ;

  flake.modules.nixos.nix = _: {
    # nix.enable is dropped - NixOS enables nix by default.
    nix.distributedBuilds = true;
    nix.buildMachines = [ homeForgeBuilder ];

    nix.settings = {
      "trusted-users" = [
        "root"
        primaryUser.name
      ];
      "extra-substituters" = [
        "https://nix-community.cachix.org"
        "https://cache.numtide.com"
        "https://cache.shrublab.xyz"
      ];
      "trusted-substituters" = [
        "ssh-ng://eu.nixbuild.net"
      ];
      "extra-trusted-public-keys" = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-cache-1:FW0bJll9BP5ch0mHI+bXOImcD0RKLrH117WfQC+CU4A="
        "nixbuild.net/HWWKWC-1:dnSfpPDHQN/U9wexkK6r3GTaYrwqNwKS70SNGXistKg="
      ];
      "experimental-features" = [
        "nix-command"
        "flakes"
      ];
      "auto-optimise-store" = true;
      "always-allow-substitutes" = true;
      "builders-use-substitutes" = true;
      "max-jobs" = "auto";
      "nix-path" = "nixpkgs=flake:nixpkgs";
      "keep-derivations" = true;
      "warn-dirty" = false;
      "accept-flake-config" = true;
      "download-buffer-size" = 268435456;
      "http-connections" = 64;
      "max-substitution-jobs" = 16;
    };
    nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];
  }

  ;
}
