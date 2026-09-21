{
  inputs,
  ...
}:
{
  # nix-fleet owns the shared treefmt definition (nixfmt, statix, deadnix,
  # prettier for Markdown/YAML/JSON, taplo) and the formatter priorities that
  # make the chain converge. This file adds only what is specific to this
  # repository.
  imports = [ inputs.nix-fleet.flakeModules.tooling ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt.settings.global.excludes = [
        "pkgs/_sources/**"
        # Pi subagent definitions are verbatim prompt text with YAML
        # frontmatter; the formatter renumbers their ordered lists and would
        # defeat byte-level comparison against upstream's bundled agents.
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
