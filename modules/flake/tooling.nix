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
        "pkgs/_sources/**"
        # nixos-facter output: a machine-generated capture, so prettier would
        # reformat it here and churn it again on every regeneration.
        "modules/hosts/*/facter.json"
        # Pi agent definitions are verbatim prompt text, compared byte-level
        # against upstream's bundled agents; the formatter renumbers their
        # ordered lists.
        "modules/agents/pi/agents/**"
        "secrets/**"
        ".brv/**"
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
          nvfetcher
          lefthook
        ];
        NIX_CONFIG = "experimental-features = nix-command flakes";
      };

      apps.nvfetcher-update = {
        type = "app";
        program =
          let
            nvfu = pkgs.writeShellScriptBin "nvfetcher-update" ''
              exec ${pkgs.nvfetcher}/bin/nvfetcher \
                -c nvfetcher.toml \
                -o pkgs/_sources \
                "$@"
            '';
          in
          "${nvfu}/bin/nvfetcher-update";
        meta.description = "Run nvfetcher to update pkgs/_sources/generated.nix and generated.json";
      };
    };
}
