{
  inputs,
  system,
}:
final: prev:
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
  byterover-cli = final.callPackage ./byterover { };
  codexbar = final.callPackage ./codexbar { };
  nirius = final.callPackage ./nirius { };
  litellm-oci = final.callPackage ./litellm/oci.nix { };
  surge = final.callPackage ./surge { inherit inputs; };
  niks3-hook = inputs.niks3.packages.${system}.niks3-hook;
  keypeek = final.callPackage ./keypeek { inherit inputs system; };
}
