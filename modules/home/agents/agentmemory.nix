{
  config,
  lib,
  pkgs,
  appsDir,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    literalExpression
    ;
  cfg = config.programs.agentmemory;
  stateDir = cfg.stateDir;
in

{
  options.programs.agentmemory = {
    enable = mkEnableOption "agentmemory — persistent memory for AI coding agents";

    package = mkOption {
      type = types.package;
      default = pkgs.agentmemory;
      defaultText = literalExpression "pkgs.agentmemory";
      description = "agentmemory package to use.";
    };

    stateDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.agentmemory";
      defaultText = literalExpression ''"''${config.home.homeDirectory}/.agentmemory"'';
      description = "Agentmemory state directory.";
    };

    settings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        AGENTMEMORY_TOOLS = "core";
        AGENTMEMORY_AUTO_COMPRESS = "true";
        CONSOLIDATION_ENABLED = "true";
        GRAPH_EXTRACTION_ENABLED = "true";
      };
      description = ''
        Env vars merged into the agentmemory .env file alongside static vars
        and the OPENAI_API_KEY secret from sops. Override per-host here.
      '';
    };

    hermesPlugin = {
      enable = mkEnableOption "Hermes integration plugin — deploys the agentmemory memory provider plugin to ~/.hermes/plugins/agentmemory";

      rev = mkOption {
        type = types.str;
        default = "1838f4d74c3a0accdd3764e7a8ec155cc140b831";
        description = "Git commit SHA to fetch the Hermes plugin from the agentmemory repo.";
      };
    };

    opencodePlugin = {
      enable = mkEnableOption "OpenCode native plugin — deploys agentmemory-capture.ts (22 hooks) + slash commands to ~/.config/opencode";

      rev = mkOption {
        type = types.str;
        default = "1838f4d74c3a0accdd3764e7a8ec155cc140b831";
        description = "Git commit SHA to fetch the OpenCode plugin from the agentmemory repo.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    sops.templates."agentmemory.env" = {
      path = "${stateDir}/.env";
      content =
        let
          settingsEnv = lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: value: "${name}=${value}") cfg.settings
          );
        in
        ''
          HOME=${config.home.homeDirectory}
          AGENTMEMORY_URL=http://localhost:3111
          AGENTMEMORY_VIEWER_URL=http://localhost:3113
          ${settingsEnv}
          OPENAI_API_KEY=sk-placeholder
        '';
    };

    home.activation.agentmemoryConfig = lib.hm.dag.entryAfter [ "sops-nix" ] ''
      systemctl --user try-restart agentmemory 2>/dev/null || true
    '';

    home.file."${config.home.homeDirectory}/.hermes/plugins/agentmemory" =
      mkIf (cfg.hermesPlugin.enable)
        {
          source =
            builtins.fetchTree {
              type = "github";
              owner = "rohitg00";
              repo = "agentmemory";
              rev = cfg.hermesPlugin.rev;
            }
            + "/integrations/hermes";
          recursive = true;
          onChange = "systemctl --user restart hermes-agent || true";
        };

    home.file.".dotfiles/apps/opencode/plugins/agentmemory-capture.ts" =
      mkIf (cfg.opencodePlugin.enable)
        {
          source =
            builtins.fetchTree {
              type = "github";
              owner = "rohitg00";
              repo = "agentmemory";
              rev = cfg.opencodePlugin.rev;
            }
            + "/plugin/opencode/agentmemory-capture.ts";
        };

    home.file.".dotfiles/apps/opencode/commands/recall.md" = mkIf (cfg.opencodePlugin.enable) {
      source =
        builtins.fetchTree {
          type = "github";
          owner = "rohitg00";
          repo = "agentmemory";
          rev = cfg.opencodePlugin.rev;
        }
        + "/plugin/opencode/commands/recall.md";
    };

    home.file.".dotfiles/apps/opencode/commands/remember.md" = mkIf (cfg.opencodePlugin.enable) {
      source =
        builtins.fetchTree {
          type = "github";
          owner = "rohitg00";
          repo = "agentmemory";
          rev = cfg.opencodePlugin.rev;
        }
        + "/plugin/opencode/commands/remember.md";
    };

    systemd.user.services.agentmemory = {
      Unit = {
        Description = "agentmemory — persistent memory daemon";
        After = [
          "sops-nix.service"
          "network-online.target"
        ];
        Wants = [
          "sops-nix.service"
          "network-online.target"
        ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/agentmemory";
        Restart = "on-failure";
        RestartSec = "5";
        WorkingDirectory = stateDir;
        StandardOutput = "journal";
        StandardError = "journal";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
