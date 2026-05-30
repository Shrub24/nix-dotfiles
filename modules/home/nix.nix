{
  config,
  lib,
  pkgs,
  ...
}:
{
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

  programs.nix-index = {
    enable = true;
  };

  programs.nix-search-tv = {
    enable = true;
  };

  programs.nix-your-shell = {
    enable = true;
    enableZshIntegration = true;
  };

  nix = {
    package = pkgs.nix;

    settings = {
      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://cache.numtide.com"
        "https://cache.shrublab.xyz"
        "ssh-ng://eu.nixbuild.net"
      ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-cache-1:FW0bJll9BP5ch0mHI+bXOImcD0RKLrH117WfQC+CU4A="
        "nixbuild.net/HWWKWC-1:dnSfpPDHQN/U9wexkK6r3GTaYrwqNwKS70SNGXistKg="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      keep-derivations = true;
      warn-dirty = false;
    };

    gc = {
      automatic = false;
    };
  };

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

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "zsh-abbr"
      "iii-engine"
    ];
}
