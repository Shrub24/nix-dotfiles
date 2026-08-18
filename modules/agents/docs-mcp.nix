_: {
  flake.modules.homeManager.docs-mcp =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.docsMcp;
      webServices = (import ../../lib/web-services.nix { inherit lib; }).services;
    in
    {
      options.programs.docsMcp = {
        enable = lib.mkEnableOption "docs-mcp-server (grounded docs)";

        port = lib.mkOption {
          type = lib.types.port;
          default = webServices.docs-mcp.port;
          description = "HTTP port for the docs-mcp-server.";
        };

        package = lib.mkOption {
          type = lib.types.str;
          default = "@arabold/docs-mcp-server@latest";
          description = "npm package to run via bunx.";
        };
      };

      config = lib.mkIf cfg.enable {
        # Docs MCP owns its env template (cross-module placeholder from credentials).
        sops.templates."docs-mcp.env".content = ''
          OPENAI_API_KEY=${config.sops.placeholder.LITELLM_API_KEY}
        '';

        systemd.user.services.docs-mcp = {
          Unit = {
            Description = "Grounded Docs MCP Server";
            After = [
              "sops-nix.service"
              "network-online.target"
            ];
            Wants = [ "network-online.target" ];
            X-Restart-Triggers = [
              config.sops.templates."docs-mcp.env".path
            ];
          };

          Service = {
            Type = "exec";
            ExecStart = "${pkgs.bun}/bin/bunx ${cfg.package} --protocol http --port ${toString cfg.port}";
            Restart = "on-failure";
            RestartSec = "10s";
            Environment = [
              "OPENAI_API_BASE=http://localhost:${toString config.programs.litellm.port}/v1"
              "DOCS_MCP_EMBEDDING_MODEL=embedding"
              "DOCS_MCP_EMBEDDINGS_VECTOR_DIMENSION=4096"
            ];
            EnvironmentFile = [ config.sops.templates."docs-mcp.env".path ];
            StandardOutput = "journal";
            StandardError = "journal";
          };

          Install = {
            WantedBy = [ "default.target" ];
          };
        };
      };
    }

  ;
}
