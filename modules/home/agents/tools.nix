{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.programs.agentTools;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  options.programs.agentTools = {
    enable = lib.mkEnableOption "AI agent CLI tools (snip, codebase-memory-mcp, xberg-cli)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      brave-search-cli
      inputs.codebase-memory-mcp.packages.${system}.default
      pkgs.xberg-cli
    ];
  };
}
