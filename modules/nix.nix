{ inputs, ... }:
let
  # systemManager lacks nix.buildMachines (#466); renders into /etc/nix/machines instead.
  # The builder's architecture comes from its fleet registry entry — the local
  # machine's arch is never assumed to be the builder's.
  homeForgeBuilder = system: {
    hostName = "home-forge";
    sshUser = "dev";
    sshKey = "/root/.ssh/nix-remote";
    protocol = "ssh-ng";
    inherit system;
    maxJobs = 2;
    # The build hook ranks remote machines against each other only — any free
    # remote slot beats local capacity — so `mandatoryFeatures`, not
    # `speedFactor`, decides which derivations are sent here.
    mandatoryFeatures = [ "nixos-test" ];
    speedFactor = 2;
    supportedFeatures = [
      "big-parallel"
      "kvm"
      "nixos-test"
    ];
  };
  homeForgeMachinesLine =
    system:
    let
      builder = homeForgeBuilder system;
      optionalField = values: if values == [ ] then "-" else builtins.concatStringsSep "," values;
    in
    "${builder.protocol}://${builder.sshUser}@${builder.hostName} ${builder.system} ${builder.sshKey} ${toString builder.maxJobs} ${toString builder.speedFactor} ${optionalField builder.supportedFeatures} ${optionalField builder.mandatoryFeatures}";

  # Substitution policy, owned by the system-scoped classes because the daemon
  # is what substitutes: an unresponsive substituter must cost seconds, not
  # minutes per path, and a cold cache must not be stampeded by the fan-out.
  substitutionSettings = {
    "connect-timeout" = 5;
    "stalled-download-timeout" = 30;
    "download-attempts" = 2;
    "http-connections" = 8;
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
      # command-not-found never read a locally built index. The import also
      # supplies `comma-with-db`, which is why plain `comma` is not installed.
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

      nix.package = lib.mkDefault pkgs.nix;

      nix.extraOptions = ''
        !include ${config.sops.templates."nix-access-tokens".path}
      '';

      programs.nh = {
        enable = true;
        # GC has exactly one owner per host. On the non-NixOS host
        # (`targets.genericLinux`, where nothing system-scoped can collect the
        # store) this user timer (`nh clean user`) is it; on NixOS the fleet's
        # `nh-gc` capability, selected by flake.modules.nixos.nix, runs
        # `nh clean all` as root, which covers user generations too.
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

      environment.etc."nix/machines" = {
        text = homeForgeMachinesLine config.currentHost.peers.home-forge.system + "\n";
        mode = "0644";
      };

      nix.settings = substitutionSettings // {
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
        "post-build-hook" = lib.getExe niks3UploadHook;
      };

      environment.etc."profile.d/nix-path.sh".text = ''
        export NIX_PATH=nixpkgs=flake:nixpkgs
      '';
    }

  ;

  flake.modules.nixos.builders =
    { config, ... }:
    {
      # Selected by hosts that hand builds to the fleet builder; a host that
      # does not select it needs no root ssh key. GC stays in the nix aspect.
      nix.distributedBuilds = true;
      nix.buildMachines = [ (homeForgeBuilder config.currentHost.peers.home-forge.system) ];
    };

  flake.modules.nixos.nix =
    { config, ... }:
    {
      # System-scoped GC: `nh clean all` as root is the only thing that can
      # collect the system profile, and it covers user generations as well, so
      # this is the NixOS host's single GC owner (the Home Manager timer is off
      # there — see flake.modules.homeManager.nix above). nix-fleet owns the
      # unit, its timer and its failure registration; this aspect selects it and
      # binds the retention policy.
      imports = [ inputs.nix-fleet.modules.nixos.nh-gc ];

      services.nh-gc = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep-since 7d";
      };

      nix.settings = substitutionSettings // {
        "trusted-users" = [
          "root"
          config.currentHost.primaryUser.name
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
      };
      nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];
    }

  ;
}
