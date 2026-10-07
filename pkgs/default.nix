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
  # Plugin recipes only: which of them a build compiles in is the caller's
  # selection, so `pi-bolt` takes `plugins` (see pkgs/pi-plugins).
  pi-plugins = final.callPackage ./pi-plugins { piExtensions = inputs.pi-extensions; };
  # The source tree and the AOT runtime are one upstream release (nvfetcher.toml),
  # so `version` is that tag minus the prefix upstream puts on it.
  pi-bolt = final.callPackage ./pi-bolt {
    src = generatedSources.pi-bolt.src;
    version = final.lib.removePrefix "bolt-v" generatedSources.pi-bolt.version;
    runtime = generatedSources.pi-bolt-runtime.src;
    piPlugins = final.pi-plugins;
  };
  nix-search-tv-fzf = final.callPackage ./nix-search-tv-fzf { };
  nixos-boot = final.callPackage ./nixos-boot { src = inputs.nixos-boot; };
  xberg-cli = final.callPackage ./xberg-cli {
    inherit (generatedSources.xberg-cli) version src;
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
