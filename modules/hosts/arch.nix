{
  config,
  inputs,
  ...
}:
let
  hostFacts = import ./arch/_facts.nix;
  system = hostFacts.architecture;
  overlay = import ../../pkgs { inherit inputs system hostFacts; };
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [ overlay ];
  };
  homepage = import ../../lib/web-services.nix {
    inherit (pkgs) lib;
  };
  hmAspect = name: config.flake.modules.homeManager.${name};
  systemAspect = name: config.flake.modules.systemManager.${name};
  # niri must stay selected AFTER monique and BEFORE noctalia: home-manager
  # types.lines merge in reverse module order, so the relative order below
  # reproduces the pre-migration rendered niri config.kdl exactly.
  hmAspects = [
    "pi"
    "hermes"
    "tools"
    "dev-tools"
    "languages"
    "lazyjournal"
    "mise"
    "navi"
    "direnv"
    "monique"
    "niks3"
    "niri"
    "nix"
    "noctalia"
    "opencode"
    "ssh"
    "mutagen"
    "mosh"
    "tailscale"
    "secrets"
    "grist"
    "litellm"
    "docs-mcp"
    "qmd"
    "web-catalog"
    "shell"
    "fish"
    "zsh"
    "tmux"
    "wezterm"
  ];
  systemAspects = [
    "network"
    "boot"
    "ssh"
    "tailscale"
    "greeter"
    "nix"
    "nixbuild"
  ];
  specialArgs = {
    inherit inputs hostFacts;
  };
  homeConfiguration = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = specialArgs;
    modules = [ ./arch/_home.nix ] ++ map hmAspect hmAspects;
  };
  systemConfiguration = inputs.system-manager.lib.makeSystemConfig {
    modules = [ ./arch/_system.nix ] ++ map systemAspect systemAspects;
    inherit specialArgs;
    overlays = [ overlay ];
  };
in
{
  flake.homeConfigurations.${hostFacts.username} = homeConfiguration;

  flake.systemConfigs.${hostFacts.hostname} = systemConfiguration;

  # Forces full eval of both configurations under nix flake check without switching.
  flake.checks.${system} = {
    home-manager-activation = homeConfiguration.activationPackage;
    system-manager-config = systemConfiguration;
  };

  flake.webServices = homepage.catalog;
  flake.webServiceCatalog = homepage.normalize homepage.catalog;
  flake.webServiceCatalogJSON = pkgs.writeText "web-service-catalog.json" (
    builtins.toJSON (homepage.toCatalogJSON homepage.catalog)
  );
}
