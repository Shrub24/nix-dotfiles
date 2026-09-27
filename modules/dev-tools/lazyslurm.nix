{ inputs, ... }: {
  # Not in nixpkgs, and upstream maintains its own buildRustPackage, so the
  # input is consumed rather than a recipe reimplemented here.
  flake-file.inputs.lazyslurm = {
    url = "github:hill/lazyslurm";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.homeManager.lazyslurm =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.lazyslurm;
    in
    {
      options.programs.lazyslurm = {
        enable = lib.mkEnableOption "lazyslurm — TUI for Slurm HPC clusters";

        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.lazyslurm.packages.${pkgs.stdenv.hostPlatform.system}.default;
          defaultText = lib.literalExpression "inputs.lazyslurm.packages.<system>.default";
          description = "The lazyslurm package to install.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];
      };
    };
}
