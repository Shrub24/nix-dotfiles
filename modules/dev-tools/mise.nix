{ inputs, ... }:
{
  flake.modules.homeManager.mise =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.programs.miseTools = {
        enable = lib.mkEnableOption "mise management for pnpm, bun, and node";

        node = lib.mkOption {
          type = lib.types.str;
          default = "lts";
          description = "Node.js version to manage via mise.";
        };

        pnpm = lib.mkOption {
          type = lib.types.str;
          default = "latest";
          description = "pnpm version to manage via mise.";
        };

        bun = lib.mkOption {
          type = lib.types.str;
          default = "latest";
          description = "Bun version to manage via mise.";
        };
      };

      config = lib.mkIf config.programs.miseTools.enable {
        home.packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.openspec ];

        programs.mise = {
          enable = true;
          enableFishIntegration = true;

          globalConfig.tools = {
            node = config.programs.miseTools.node;
            pnpm = config.programs.miseTools.pnpm;
            bun = config.programs.miseTools.bun;
            aube = "latest";
          };
        };
      };
    }

  ;
}
