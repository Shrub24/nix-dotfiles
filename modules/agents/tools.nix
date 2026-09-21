{ inputs, ... }:
{
  flake-file.inputs = {
    codebase-memory-mcp.url = "github:DeusData/codebase-memory-mcp/v0.11.0";
    memex.url = "github:nicosuave/memex";
  };

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
          # cass disabled 2026-09-20: trialling memex for session recall;
          # derivation + nvfetcher source kept for quick re-enable.
          # memex trial parked 2026-09-20: ort-sys ONNX build needs
          # ORT_LIB_PATH/ORT_PREFER_DYNAMIC_LINK overrides (patch drafted
          # in git history); flake input memex stays pinned.
        ];
      };
    };

}
