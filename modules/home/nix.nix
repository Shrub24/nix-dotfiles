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

  programs.nix-init = {
    enable = true;
    settings = {
      nixpkgs = "builtins.getFlake \"nixpkgs\"";
    };
  };

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

  nix.package = pkgs.nix;

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
      "byterover-cli"
    ];
}
