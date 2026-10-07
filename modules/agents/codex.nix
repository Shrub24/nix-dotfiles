{ inputs, ... }:
{
  # NixOS-only package aspect: it rides embeddedHmAspects, not the shared list.
  flake.modules.homeManager.codex =
    { pkgs, ... }:
    {
      home.packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex ];
    };
}
