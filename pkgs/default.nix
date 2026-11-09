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
    # The producer's builds, taken by name: a plugin this repository uses is the
    # one pi-extensions publishes, not a copy built here.
    piExtensionPlugins = inputs.pi-extensions.packages.${system};
    # Its lock candidates, so the plugin lock's members are named from the
    # producer's own manifests and pins.
    piExtensionLockCandidates = inputs.pi-extensions.lib.pluginLockCandidates;
    piPowerlineFooter = inputs.pi-powerline-footer;
    inherit (piBoltPkgs) piBoltPlugins;
    piBolt = piBoltPkgs.pi-bolt;
  };
  pi-freeflow = final.callPackage ./pi-freeflow { };
  pi-magic-context = inputs.magic-context.packages.${system}.pi-magic-context;
  pi-bolt = final.callPackage ./pi-bolt {
    piBolt = piBoltPkgs.pi-bolt;
    pluginLock = ./pi-plugins/plugins.lock.json;
  };
  nix-search-tv-fzf = final.callPackage ./nix-search-tv-fzf { };
  mo-viewer = inputs.nixpkgs-fork.legacyPackages.${system}.mo-viewer;
  # Upstream fix, one day younger than our nixpkgs pin; see context/mcp-nixos-mcp1.md.
  mcp-nixos = _prev.mcp-nixos.override {
    python3Packages = _prev.python3Packages.overrideScope (
      pythonFinal: _: { mcp = pythonFinal.mcp_1; }
    );
  };
  # Upstream fix, hours younger than our nixpkgs pin; see context/intelli-shell-aws-lc.md.
  intelli-shell = _prev.intelli-shell.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ final.aws-lc ];
  });
  # One release ahead of our nixpkgs pin: niri is in its portal file there, and
  # the wrapper's command injection is closed; see context/legion-desktop.md.
  xdg-desktop-portal-termfilechooser = final.callPackage ./xdg-desktop-portal-termfilechooser {
    inherit (_prev) xdg-desktop-portal-termfilechooser;
  };
  jj-hunk-tool = final.callPackage ./jj-hunk-tool { };
  nixos-boot = final.callPackage ./nixos-boot { src = inputs.nixos-boot; };
  xberg-cli = final.callPackage ./xberg-cli { };
  codexbar = final.callPackage ./codexbar { };
  herdr-nvim-zoom = final.callPackage ./herdr-nvim-zoom {
    herdr = inputs.llm-agents.packages.${system}.herdr;
  };
  hermes-agent = final.callPackage ./hermes-agent {
    hermes-agent = inputs.hermes-agent.packages.${system}.minimal;
  };
  umbriel-completions = final.callPackage ./umbriel-completions {
    umbriel = inputs.umbriel.packages.${system}.default;
  };
}
