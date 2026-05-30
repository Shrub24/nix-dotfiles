{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.docsMcp;
in
{
  options.programs.docsMcp = {
    enable = lib.mkEnableOption "docs-mcp-server (grounded docs)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 6280;
      description = "HTTP port for the docs-mcp-server.";
    };

    package = lib.mkOption {
      type = lib.types.str;
      default = "@arabold/docs-mcp-server@latest";
      description = "npm package to run via bunx.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.docs-mcp = {
      Unit = {
        Description = "Grounded Docs MCP Server";
        After = [
          "sops-nix.service"
          "network-online.target"
        ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "exec";
        ExecStart = "${pkgs.bun}/bin/bunx ${cfg.package} --protocol http --port ${toString cfg.port}";
        Restart = "on-failure";
        RestartSec = "10s";
        Environment = [
          "OPENAI_API_BASE=http://localhost:8765/v1"
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

    home.activation.docsMcpConfig = lib.hm.dag.entryAfter [ "sops-nix" ] ''
      systemctl --user try-restart docs-mcp.service 2>/dev/null || true
    '';
  };
}
