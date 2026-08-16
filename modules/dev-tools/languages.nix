_: {
  flake.modules.homeManager.languages =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.devTools;
    in
    {
      options.programs.devTools = {
        enable = lib.mkEnableOption "CLI and language dev tools (ast-grep, tree-sitter, grammars)";

        treeSitterGrammars = lib.mkOption {
          description = "Extra tree-sitter grammars to make available system-wide";
          type = with lib.types; listOf package;
          default = [ ];
          example = lib.literalExpression "[ pkgs.tree-sitter-grammars.tree-sitter-just ]";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages =
          with pkgs;
          [
            ast-grep
            tree-sitter
          ]
          ++ cfg.treeSitterGrammars;

      };
    }

  ;
}
