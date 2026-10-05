{ inputs, ... }:
let
  # nix-fleet's nix-baseline is NixOS-only; this is the non-NixOS policy.
  substitutionSettings = {
    "connect-timeout" = 5;
    "stalled-download-timeout" = 30;
    "download-attempts" = 2;
    "http-connections" = 50;
    "max-substitution-jobs" = 8;
    # Misses are cheap; the built-in one-hour negative cache is not.
    "narinfo-cache-negative-ttl" = 60;
  };
in
{
  flake-file.inputs.nix-index-database = {
    url = "github:nix-community/nix-index-database";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.homeManager.nix =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      # Prebuilt database as a hash-pinned store path, so nix-locate and
      # command-not-found never read a built index; supplies `comma-with-db`.
      imports = [ inputs.nix-index-database.homeModules.nix-index ];

      sops.templates."nix-access-tokens" = {
        path = "${config.home.homeDirectory}/.config/nix/access-tokens.conf";
        content = "access-tokens = github.com=${config.sops.placeholder.GITHUB_PAT}\n";
      };

      home.packages = with pkgs; [
        nixd
        nvd
        nix-init
        statix
        deadnix
        nixfmt
        nix-output-monitor
        nix-tree
        manix
        envfs
        nix-ld
        nix-fast-build
        nix-update
        niks3
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

        nix-index-database.comma.enable = true;

        nix-search-tv = {
          enable = true;
        };

        nix-your-shell = {
          enable = true;
          enableZshIntegration = true;
        };
      };

      nix.package = lib.mkDefault pkgs.nixVersions.latest;

      nix.extraOptions = ''
        !include ${config.sops.templates."nix-access-tokens".path}
      '';

      programs.nh = {
        enable = true;
        # GC has one owner per host: the user timer here, the fleet's root
        # `nh-gc` capability on NixOS.
        clean = {
          enable = config.targets.genericLinux.enable;
          dates = "weekly";
          extraArgs = "--keep-since 7d";
        };
      };
    }

  ;

  flake.modules.systemManager.nix =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      primaryUser = config.currentHost.primaryUser;
      inherit (primaryUser) uid;

      niks3UploadHook = pkgs.writeShellScriptBin "niks3-upload-hook" ''
        exec ${lib.getExe' pkgs.niks3 "niks3-hook"} send --socket /run/user/${toString uid}/niks3-upload-to-cache.sock
      '';
    in
    {
      nix.enable = true;
      # The upstream remote-build module otherwise sets builders = null.
      nix.distributedBuilds = true;

      nix.settings = substitutionSettings // {
        # "root" is already the module default and this list concatenates.
        "trusted-users" = [ primaryUser.name ];
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
        # Local builds are the overflow path; `cores` bounds each build's own
        # parallelism so one long build cannot take the whole machine.
        "max-jobs" = 4;
        "cores" = 4;
        "keep-derivations" = true;
        "warn-dirty" = false;
        "accept-flake-config" = true;
        "download-buffer-size" = 268435456;
        "post-build-hook" = lib.getExe niks3UploadHook;
        "nix-path" = [ "nixpkgs=flake:nixpkgs" ];
      };

      # Builds are children of the daemon here, so the unit's cgroup bounds them;
      # system-manager has no `nix.daemon*Policy` options.
      systemd.services.nix-daemon.serviceConfig = {
        CPUSchedulingPolicy = "batch";
        IOSchedulingClass = "idle";
        CPUWeight = 50;
        MemoryHigh = "8G";
      };
    }

  ;

  flake.modules.nixos.nix =
    { config, ... }:
    {
      # nix-fleet owns the daemon baseline and the GC unit; this selects them and
      # binds what is host-specific (identity, I/O class, memory, evaluation knobs).
      imports = [
        inputs.nix-fleet.modules.nixos.nix-baseline
        inputs.nix-fleet.modules.nixos.nix-gc
      ];

      # Importing is the enable — the fleet aspects declare no `enable`.
      services.nix-gc = {
        dates = "weekly";
        extraArgs = "--keep-since 7d";
      };

      nix.settings = {
        # nixpkgs already lists "root" and this list concatenates, so naming it
        # again renders a duplicate.
        "trusted-users" = [ config.currentHost.primaryUser.name ];
        # Local builds are the overflow path; `cores` keeps one long build from
        # taking the whole machine.
        "max-jobs" = 4;
        "cores" = 4;
        "keep-derivations" = true;
        "warn-dirty" = false;
        "accept-flake-config" = true;
        "nix-path" = [ "nixpkgs=flake:nixpkgs" ];
      };

      # The fleet contract owns CPU policy, weights and I/O priority; the hosts keep
      # idle I/O (so that priority is inert) and bound daemon memory themselves.
      nix.daemonIOSchedClass = "idle";
      systemd.services.nix-daemon.serviceConfig.MemoryHigh = "8G";
    }

  ;
}
