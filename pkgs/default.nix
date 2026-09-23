{
  inputs,
  system,
}:
final: _prev:
let
  generatedSources = import ./_sources/generated.nix {
    inherit (final)
      fetchgit
      fetchurl
      fetchFromGitHub
      dockerTools
      ;
  };
in
{
  nix-search-tv-fzf = final.callPackage ./nix-search-tv-fzf { };
  xberg-cli = final.callPackage ./xberg-cli {
    inherit (generatedSources.xberg-cli) version src;
  };
  byterover-cli = final.callPackage ./byterover {
    inherit (generatedSources.byterover-cli) version src;
  };
  codexbar = final.callPackage ./codexbar {
    inherit (generatedSources.codexbar) version src;
  };
  noctalia-template-hooks = final.callPackage ./noctalia-template-hooks { };
  herdr-nvim-zoom = final.callPackage ./herdr-nvim-zoom {
    herdr = inputs.llm-agents.packages.${system}.herdr;
  };
  keypeek = final.callPackage ./keypeek { inherit inputs system; };
}
