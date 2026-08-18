{
  config,
  inputs,
  ...
}:
let
  # Host-local literals for the Arch desktop host (B11: former facts folded out
  # into topology + these literals; _facts.nix removed).
  primaryUser = "saurabhj";
  system = "x86_64-linux";
  overlay = import ../../pkgs { inherit inputs system; };
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [ overlay ];
  };
  homepage = import ../../lib/web-services.nix {
    inherit (pkgs) lib;
  };
  hmAspect = name: config.flake.modules.homeManager.${name};
  systemAspect = name: config.flake.modules.systemManager.${name};
  nixosAspect = name: config.flake.modules.nixos.${name};
  hmAspects = [
    "pi"
    "hermes"
    "tools"
    "dev-tools"
    "cli"
    "languages"
    "intelli-shell"
    "lazyjournal"
    "mise"
    "direnv"
    "monique"
    "niks3"
    "niri"
    "nix"
    "noctalia"
    "opencode"
    "portals"
    "fonts"
    "ghostty"
    "kde-apps"
    "pavucontrol"
    "libinput"
    "zathura"
    "media"
    "libreoffice"
    "util-apps"
    "syncthing"
    "ssh"
    "mutagen"
    "mosh"
    "tailscale"
    "vicinae"
    "audio"
    "brave"
    "chromium"
    "credentials"
    "firefox"
    "thunderbird"
    "vscode"
    "sops-foundation"
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
  nixosAspects = [ "foundation" ];
  homeConfiguration = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [ ./arch/_home.nix ] ++ map hmAspect hmAspects;
  };
  systemConfiguration = inputs.system-manager.lib.makeSystemConfig {
    modules = [ ./arch/_system.nix ] ++ map systemAspect systemAspects;
    overlays = [ overlay ];
  };
  nixosConfiguration = inputs.nixpkgs.lib.nixosSystem {
    modules = [ ./arch/_nixos.nix ] ++ map nixosAspect nixosAspects;
    specialArgs = { }; # empty — NO inputs/hostFacts bus; maintain cleanup invariant
  };
in
{
  config = {
    # Typed topology (B2/B11): host + service facts now live here, read via
    # `config.topology` by feature modules — not through an argument-passing bus.
    topology.hosts.arch = {
      inherit system;
      primaryUser = primaryUser;
      remoteHosts = [
        "oci-melb-1"
        "do-admin-1"
        "la-admin-1"
      ];
    };
    topology.services.database.host = "oci-melb-1";
    topology.services.niks3.host = "http://oci-melb-1:5751";

    flake.homeConfigurations.${primaryUser} = homeConfiguration;

    flake.systemConfigs.arch = systemConfiguration;
    flake.nixosConfigurations.arch = nixosConfiguration;

    # Forces full eval of all configurations under nix flake check without switching.
    flake.checks.${system} = {
      home-manager-activation = homeConfiguration.activationPackage;
      system-manager-config = systemConfiguration;
      nixos-system = nixosConfiguration.config.system.build.toplevel;
    };

    flake.webServices = homepage.catalog;
    flake.webServiceCatalog = homepage.normalize homepage.catalog;
    flake.webServiceCatalogJSON = pkgs.writeText "web-service-catalog.json" (
      builtins.toJSON (homepage.toCatalogJSON homepage.catalog)
    );
  };
}
