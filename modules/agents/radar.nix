{ inputs, ... }:
{
  flake-file.inputs.agent-radar = {
    url = "github:Shrub24/agent-radar";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.homeManager.radar = {
    imports = [ inputs.agent-radar.homeManagerModules.default ];

    programs.radar = {
      enable = true;
      # Every key Radar reads has a default, so the file is Nix-owned and carries
      # no overrides; its palette is Noctalia's, rendered to a file of its own.
      settings = { };
    };
  };
}
