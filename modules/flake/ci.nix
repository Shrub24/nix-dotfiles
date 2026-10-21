{
  config,
  inputs,
  lib,
  ...
}:
{
  # The fleet build target (`targets: .#ciRoot`): the non-VM outputs CI builds for
  # each system. The VM tests are manual tools and stay out of it.
  flake.ciRoot = lib.genAttrs config.systems (
    system:
    let
      checks = config.flake.checks.${system};
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
    )
  );
}
