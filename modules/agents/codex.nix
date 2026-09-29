{ inputs, ... }:
{
  # Arch gets codex from the AUR, so this package aspect is NixOS-only and rides
  # embeddedHmAspects rather than the shared hmAspects list.
  flake.modules.homeManager.codex =
    { pkgs, ... }:
    {
      home.packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex ];
    };
}
