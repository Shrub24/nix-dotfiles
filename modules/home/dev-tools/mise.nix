{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.mise;
in
{
  options.programs.miseTools = {
    enable = lib.mkEnableOption "mise management for pnpm, bun, and node";

    node = lib.mkOption {
      type = lib.types.str;
      default = "lts";
      description = "Node.js version to manage via mise.";
    };

    pnpm = lib.mkOption {
      type = lib.types.str;
      default = "latest";
      description = "pnpm version to manage via mise.";
    };

    bun = lib.mkOption {
      type = lib.types.str;
      default = "latest";
      description = "Bun version to manage via mise.";
    };
  };

  config = lib.mkIf config.programs.miseTools.enable {
    programs.mise = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      package = pkgs.mise;

      globalConfig.tools = lib.filterAttrs (_: v: v != null) {
        node = config.programs.miseTools.node;
        pnpm = config.programs.miseTools.pnpm;
        bun = config.programs.miseTools.bun;
        aube = "latest";

        "npm:ocx" = "latest";
        "npm:codeburn" = "latest";
        "npm:neovim" = "latest";
        "npm:matlab-language-server" = "latest";
        "npm:@fission-ai/openspec" = "latest";
        "npm:@getpaseo/cli" = "latest";
        # "npm:@happier-dev/cli" = "latest";
        # "npm:@tobilu/qmd" = {
        #   version = "latest";
        #   aube_args = "--allow-build=better-sqlite3,node-llama-cpp,tree-sitter-go,tree-sitter-javascript,tree-sitter-python,tree-sitter-rust,tree-sitter-typescript";
        # };
      };
    };
  };
}
