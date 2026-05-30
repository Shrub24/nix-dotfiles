{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # Import from non-flake source to avoid checks.nix syntax error
  upstreamModule =
    (import "${inputs.hermes-agent-src}/nix/homeManagerModules.nix" {
      inherit inputs;
    }).flake.homeManagerModules.default;
in
{
  imports = [ upstreamModule ];

  programs.hermes-agent = {
    enable = lib.mkDefault false;
    package = lib.mkDefault inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
    mcpServers = lib.mkIf (config.programs.agentmemory.enable or false) {
      agentmemory = {
        command = "aubx";
        args = [ "@agentmemory/mcp" ];
        env.AGENTMEMORY_URL = "http://localhost:3111";
      };
    };
    settings = lib.mkDefault (
      lib.mkIf (config.programs.agentmemory.enable or false) {
        memory.provider = "agentmemory";
      }
    );
  };
}
