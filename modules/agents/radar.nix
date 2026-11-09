{ inputs, ... }:
{
  flake-file.inputs.agent-radar = {
    url = "github:Shrub24/agent-radar";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.homeManager.radar = {
    imports = [ inputs.agent-radar.homeManagerModules.default ];

    programs.radar.enable = true;
  };
}
