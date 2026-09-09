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
  nirius = final.callPackage ./nirius {
    inherit (generatedSources.nirius) version src;
  };
  cass = final.callPackage ./cass {
    inherit inputs system;
    inherit (generatedSources.cass) version src;
  };
  litellm-oci = final.callPackage ./litellm/oci.nix { };
  models-dev = final.callPackage ./models-dev { };
  noctalia-template-hooks = final.callPackage ./noctalia-template-hooks { };
  niks3-hook = inputs.niks3.packages.${system}.niks3-hook;
  keypeek = final.callPackage ./keypeek { inherit inputs system; };
}
