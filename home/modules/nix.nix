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
    comma
    nix-your-shell
    tokei
  ];

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.nix-your-shell = {
    enable = true;
    enableZshIntegration = true;
  };

  nix = {
    package = pkgs.nix;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      keep-derivations = true;
      warn-dirty = false;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "zsh-abbr"
    ];
}
