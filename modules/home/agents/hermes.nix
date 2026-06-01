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
        command = "agentmemory";
        args = [ "mcp" ];
        env.AGENTMEMORY_URL = "http://localhost:3111";
      };
    };
    settings = lib.mkDefault {
      model = {
        provider = "custom";
        base_url = "http://localhost:8765/v1";
        default = "summariser";
      };
      auxiliary = {
        vision = {
          provider = "main";
          model = "image";
          timeout = 30;
        };
        web_extract = {
          provider = "main";
          model = "budget";
        };
        session_search = {
          provider = "main";
        };
      };
      memory = lib.mkIf (config.programs.agentmemory.enable or false) {
        provider = "agentmemory";
      };
    };
  };
}
