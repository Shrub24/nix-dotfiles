{
  inputs,
  ...
}:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";

        settings.global.excludes = [
          "pkgs/_sources/**"
          # Pi subagent definitions are verbatim prompt text with YAML
          # frontmatter; mdformat would renumber their ordered lists and
          # defeat byte-level comparison against upstream's bundled agents.
          "modules/agents/pi/agents/**"
          "secrets/**"
          ".brv/**"
          ".qmd/**"
          ".direnv/**"
          ".jj/**"
          ".opencode/**"
          ".pi/**"
          ".ocx/**"
          ".firecrawl/**"
          "result"
          "result-*"
          "flake.lock"
        ];

        programs = {
          nixfmt.enable = true;
          statix.enable = true;
          deadnix.enable = true;
          mdformat.enable = true;
          mdformat.plugins = ps: [ ps.mdformat-frontmatter ];
          taplo.enable = true;
          yamlfmt.enable = true;
          jsonfmt.enable = true;
        };
      };

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
