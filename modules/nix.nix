{ inputs, ... }:
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
      };
    }

  ;

  flake.modules.nixos.nix =
    { config, ... }:
    {
      # nix-fleet owns the daemon baseline and the cleanup units; this selects
      # them and binds what is host-specific (identity, I/O class, memory,
      # evaluation knobs).
      imports = [
        inputs.nix-fleet.modules.nixos.nix-baseline
        inputs.nix-fleet.modules.nixos.nix-gc
      ];

      # btrfs, and auto-optimise-store already dedups each path as it is written,
      # so the pass has nothing to find.
      services.fast-nix-optimise.enable = false;

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
