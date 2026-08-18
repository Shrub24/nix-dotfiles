{ inputs, ... }: {
  flake.modules.homeManager.pi =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.pi;
    in
    {
      options.programs.pi = {
        enable = lib.mkEnableOption "pi coding agent";

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.pi;
          defaultText = lib.literalExpression "pkgs.pi";
          description = "The pi coding agent package to use.";
        };

        settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Freeform settings rendered to ~/.pi/agent/settings.json.";
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          home.packages = [ cfg.package ];

          home.file.".pi/agent/settings.json" = lib.mkIf (cfg.settings != { }) {
            text = builtins.toJSON cfg.settings;
          };
        })
        # programs.pi.package override (moved from flake.nix host composition):
        # unconditional, matching the pre-migration host-level override module.
        {
          programs.pi.package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;
        }
      ];
    }

  ;
}
