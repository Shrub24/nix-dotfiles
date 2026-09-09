{ inputs, ... }: {
  flake.modules.homeManager.herdr =
    { pkgs, ... }:
    {
      programs.herdr.package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
    };
}
