{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.nix-fleet.flakeModules.cacheRoot ];

  # The fleet build target (`targets: .#ciRoot`): the non-VM outputs CI builds for
  # each system. The VM tests are manual tools and stay out of it. The retention
  # root rides along, because promotion pins the root it built — `pins create`
  # refuses a path the cache does not hold.
  flake.ciRoot = lib.genAttrs config.systems (
    system:
    let
      checks = config.flake.checks.${system};
      packages = config.flake.packages.${system};
    in
    inputs.nixpkgs.legacyPackages.${system}.linkFarm "ci-root" (
      map
        (name: {
          inherit name;
          path = checks.${name};
        })
        [
          "nixos-system"
          "nixos-spectre"
          "treefmt"
          "check-flake-file"
        ]
      ++ [
        {
          name = "cache-root";
          path = packages.cache-root;
        }
      ]
    )
  );
}
