{
  inputs,
  ...
}:
{
  # nix-fleet owns the shared treefmt definition; this file adds only what is
  # specific to this repository.
  imports = [ inputs.nix-fleet.flakeModules.tooling ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt.settings.global.excludes = [
        # nixos-facter output: a machine-generated capture, so prettier would
        # reformat it here and churn it again on every regeneration.
        "modules/hosts/*/facter.json"
        # Pi agent definitions are verbatim prompt text, compared byte-level
        # against upstream's bundled agents; the formatter renumbers their
        # ordered lists.
        "modules/agents/pi/agents/**"
        "secrets/**"
        ".qmd/**"
        ".direnv/**"
        ".opencode/**"
        ".ocx/**"
        ".firecrawl/**"
      ];

      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          nixd
          nil
          statix
          deadnix
          nixfmt
          nix-output-monitor
          lefthook
        ];
        NIX_CONFIG = "experimental-features = nix-command flakes";
      };

    };
}
