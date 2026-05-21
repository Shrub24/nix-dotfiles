{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.programs.hermes;
in
{
  options.programs.hermes = {
    enable = lib.mkEnableOption "hermes-agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.hermes-agent.packages.${pkgs.system}.hermes-agent;
      defaultText = lib.literalExpression "inputs.hermes-agent.packages.${pkgs.system}.hermes-agent";
      description = "The hermes-agent package to use.";
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrs;
        options = { };
      };
      default = { };
      description = "Hermes agent configuration settings (rendered as config.yaml).";
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "MCP server configurations merged into settings.mcp_servers.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Non-secret environment variables (rendered to .env).";
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Secret file paths whose contents are merged into $HERMES_HOME/.env.";
    };

    documents = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Workspace documents installed into the working directory.";
    };

    enableGateway = lib.mkEnableOption "hermes-agent gateway systemd user service";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file = lib.mkMerge [
      # Render config.yaml from settings merged with mcp_servers
      (lib.mkIf (cfg.settings != { } || cfg.mcpServers != { }) {
        ".hermes/config.yaml" = {
          text = builtins.toJSON (
            lib.foldl' lib.recursiveUpdate { }
              [
                (lib.filterAttrsRecursive (_: v: v != null && v != [ ] && v != { }) cfg.settings)
                { mcp_servers = cfg.mcpServers; }
              ]
          );
        };
      })
      # Render .env from environment variables
      (lib.mkIf (cfg.environment != { } || cfg.environmentFiles != [ ]) {
        ".hermes/.env" = {
          text = builtins.concatStringsSep "\n"
            (lib.mapAttrsToList (k: v: "${k}=${v}") cfg.environment);
        };
      })
      # Install workspace documents as individual files
      (lib.mkIf (cfg.documents != { }) (
        lib.mapAttrs' (name: content: {
          name = ".hermes/workspace/${name}";
          value = { text = content; };
        }) cfg.documents
      ))
    ];

    # Systemd user service for hermes gateway
    systemd.user.services.hermes-agent = lib.mkIf cfg.enableGateway {
      Unit = {
        Description = "Hermes Agent Gateway";
        After = [ "network.target" ];
      };
      Service = {
        Type = "exec";
        ExecStart = "${cfg.package}/bin/hermes gateway";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = [
          "HOME=%h"
          "XDG_RUNTIME_DIR=%t"
        ] ++ lib.mapAttrsToList (k: v: "${k}=${v}") cfg.environment;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}