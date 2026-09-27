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
        sops.templates."docs-mcp.env".content = ''
          OPENAI_API_KEY=${config.sops.placeholder.VOYAGE_API_KEY}
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
            # Voyage directly rather than through OmniRoute — the gateway is
            # not embeddings-focused. The server uses this base for embeddings
            # only (it documents no chat/LLM variable), and Voyage is
            # OpenAI-shaped, so the swap is endpoint + model + key. The
            # dimension drops from 4096 to voyage-4's native 1024, which
            # invalidates the stored vectors: the index must be rebuilt once.
            Environment = [
              "OPENAI_API_BASE=https://api.voyageai.com/v1"
              "DOCS_MCP_EMBEDDING_MODEL=voyage-4"
              "DOCS_MCP_EMBEDDINGS_VECTOR_DIMENSION=1024"
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
