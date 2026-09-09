{ inputs, ... }: {
  flake.modules.homeManager.tools =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.agentTools;
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
      options.programs.agentTools = {
        enable = lib.mkEnableOption "AI agent CLI tools (codebase-memory-mcp, xberg-cli, cass)";

        cass.skill = {
          enable = lib.mkEnableOption "cass SKILL.md into the skills directory";
          dir = lib.mkOption {
            type = lib.types.str;
            default = ".agents/skills";
            description = "Home-relative directory to symlink the cass skill into";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = with pkgs; [
          brave-search-cli
          inputs.codebase-memory-mcp.packages.${system}.default
          xberg-cli
          cass
        ];

        home.file = lib.mkIf cfg.cass.skill.enable {
          "${cfg.cass.skill.dir}/cass/SKILL.md".source = "${pkgs.cass}/share/cass/SKILL.md";
        };
      };
    }

  ;
}
