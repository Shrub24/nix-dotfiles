_: {
  flake.modules.homeManager.mcp-nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.mcpNixos;
      homepage = import ../../lib/web-services.nix { inherit lib; };
    in
    {
      imports = [ ./_pi-mcp.nix ];

      options.programs.mcpNixos = {
        enable = lib.mkEnableOption "mcp-nixos (NixOS options, packages and channels over MCP)";

        enablePiIntegration = lib.mkEnableOption "connecting Pi to mcp-nixos" // {
          default = true;
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = homepage.services.mcp-nixos.port;
          description = "HTTP port for the mcp-nixos MCP server.";
        };

        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Address mcp-nixos binds. Loopback keeps it off the tailnet.";
        };

        path = lib.mkOption {
          type = lib.types.str;
          default = homepage.services.mcp-nixos.mcp.path;
          description = "Endpoint path clients POST to.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.mcp-nixos;
          description = "mcp-nixos package to run.";
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          systemd.user.services.mcp-nixos = {
            Unit = {
              Description = "mcp-nixos — NixOS knowledge MCP server";
              After = [ "network-online.target" ];
              Wants = [ "network-online.target" ];
            };

            Service = {
              Type = "exec";
              ExecStart = "${lib.getExe cfg.package}";
              # HTTP is the transport a unit can serve; stdio needs a client
              # holding this process's stdin. Everything else stays a default.
              Environment = [
                "MCP_NIXOS_TRANSPORT=http"
                "MCP_NIXOS_HOST=${cfg.host}"
                "MCP_NIXOS_PORT=${toString cfg.port}"
              ];
              Restart = "on-failure";
              RestartSec = "10s";
              StandardOutput = "journal";
              StandardError = "journal";
            };

            Install = {
              WantedBy = [ "default.target" ];
            };
          };
        })

        # Registration follows ownership, as with the fleet's notify events:
        # this module knows how a host reaches mcp-nixos, and Pi renders the
        # register. The daemon is a per-host choice; a client can still be given
        # the server where nothing serves it, in which case it spawns its own.
        (lib.mkIf cfg.enablePiIntegration {
          programs.pi-coding-agent.mcpServers.nixos = {
            description = "NixOS options and package versions.";
          }
          // (
            if cfg.enable then
              {
                url = "http://${cfg.host}:${toString cfg.port}${cfg.path}";
              }
            else
              {
                command = "uvx";
                args = [ "mcp-nixos" ];
              }
          );
        })
      ];
    }

  ;
}
