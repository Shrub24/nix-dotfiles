{
  inputs,
  ...
}:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, lib, ... }:
    {
      # pkgs/_sources is nvfetcher output; other generated.nix files are hand-maintained and stay linted.
      checks =
        let
          lintSource = lib.fileset.unions [
            ../../flake.nix
            ../../modules
            ../../lib
            ../../policy
            (lib.fileset.difference ../../pkgs ../../pkgs/_sources)
          ];
          lintFiles = lib.fileset.toSource {
            root = ../..;
            fileset = lintSource;
          };
        in
        {
          statix = pkgs.runCommandLocal "statix-check" {
            nativeBuildInputs = [ pkgs.statix ];
            src = lintFiles;
          } "statix check $src && touch $out";
          deadnix = pkgs.runCommandLocal "deadnix-check" {
            nativeBuildInputs = [ pkgs.deadnix ];
            src = lintFiles;
          } "deadnix --fail $src && touch $out";
        };

      treefmt = {
        projectRootFile = "flake.nix";

        settings.global.excludes = [
          "pkgs/_sources/**"
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
