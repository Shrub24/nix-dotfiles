{
  inputs,
  system,
}:
final: _prev:
let
  # Pi-Bolt's own package and plugin scope, on the nixpkgs this repository
  # follows: the base set extended with the flake's overlay, not the set built
  # below — the `pi-bolt` published here is this repository's launchers, and
  # reading it there would put our wrapper where the payload belongs.
  piBoltPkgs = inputs.nixpkgs.legacyPackages.${system}.extend inputs.pi-bolt-nix.overlays.default;
in
{
  # Plugin recipes only: which of them a build compiles in is the caller's
  # selection, so `pi-bolt` takes `plugins` (see pkgs/pi-plugins). Each recipe
  # becomes a plugin through the flake's own builder.
  pi-plugins = final.callPackage ./pi-plugins {
    piExtensions = inputs.pi-extensions;
    piPowerlineFooter = inputs.pi-powerline-footer;
    inherit (piBoltPkgs) piBoltPlugins;
    piBolt = piBoltPkgs.pi-bolt;
  };
  pi-otel = final.callPackage ./pi-otel { piExtensions = inputs.pi-extensions; };
  pi-freeflow = final.callPackage ./pi-freeflow { };
  pi-magic-context = inputs.magic-context.packages.${system}.pi-magic-context;
  pi-bolt = final.callPackage ./pi-bolt {
    piBolt = piBoltPkgs.pi-bolt;
    pluginLock = ./pi-plugins/plugins.lock.json;
  };
  nix-search-tv-fzf = final.callPackage ./nix-search-tv-fzf { };
  jj-hunk-tool = final.callPackage ./jj-hunk-tool { };
  nixos-boot = final.callPackage ./nixos-boot { src = inputs.nixos-boot; };
  xberg-cli = final.callPackage ./xberg-cli { };
  codexbar = final.callPackage ./codexbar { };
  noctalia-template-hooks = final.callPackage ./noctalia-template-hooks { };
  herdr-nvim-zoom = final.callPackage ./herdr-nvim-zoom {
    herdr = inputs.llm-agents.packages.${system}.herdr;
  };
  hermes-agent = final.callPackage ./hermes-agent {
    hermes-agent = inputs.hermes-agent.packages.${system}.minimal;
  };
  keypeek = final.callPackage ./keypeek { inherit inputs system; };
}
