{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.qmd;
in
{
  options.programs.qmd = {
    enable = lib.mkEnableOption "qmd — local markdown search engine (MCP HTTP server)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8181;
      description = "HTTP port for the qmd MCP server.";
    };

    package = lib.mkOption {
      type = lib.types.str;
      default = "@tobilu/qmd@latest";
      description = "npm package to run via bunx.";
    };

    gpu = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "auto" "metal" "vulkan" "cuda" "false" ]);
      default = null;
      description = "llama.cpp GPU backend override. null = default (auto).";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.qmd = {
      Unit = {
        Description = "QMD — local markdown search engine (MCP HTTP server)";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "exec";
        ExecStart = "${pkgs.bun}/bin/bunx ${cfg.package} mcp --http --port ${toString cfg.port}";
        Restart = "on-failure";
        RestartSec = "10s";
        Environment = lib.optional (cfg.gpu != null) "QMD_LLAMA_GPU=${cfg.gpu}";
        StandardOutput = "journal";
        StandardError = "journal";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
