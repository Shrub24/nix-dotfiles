{
  inputs,
  system,
}:
final: _prev: {
  # Plugin recipes only: which of them a build compiles in is the caller's
  # selection, so `pi-bolt` takes `plugins` (see pkgs/pi-plugins).
  pi-plugins = final.callPackage ./pi-plugins { piExtensions = inputs.pi-extensions; };
  pi-bolt = final.callPackage ./pi-bolt { piPlugins = final.pi-plugins; };
  nix-search-tv-fzf = final.callPackage ./nix-search-tv-fzf { };
  nixos-boot = final.callPackage ./nixos-boot { src = inputs.nixos-boot; };
  xberg-cli = final.callPackage ./xberg-cli { };
  codexbar = final.callPackage ./codexbar { };
  noctalia-template-hooks = final.callPackage ./noctalia-template-hooks { };
  herdr-nvim-zoom = final.callPackage ./herdr-nvim-zoom {
    herdr = inputs.llm-agents.packages.${system}.herdr;
  };
  keypeek = final.callPackage ./keypeek { inherit inputs system; };
}
