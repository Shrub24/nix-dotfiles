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
    enable = lib.mkEnableOption "AI agent CLI tools (snip, codebase-memory-mcp, kreuzberg-cli)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      snip
      inputs.codebase-memory-mcp.packages.${system}.default
      pkgs.kreuzberg-cli
    ];
  };
}
