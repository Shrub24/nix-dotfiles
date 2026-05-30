{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.bifrost;
in
{
  options.programs.bifrost = {
    enable = lib.mkEnableOption "bifrost MCP gateway";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.bifrost = {
      Unit = {
        Description = "Maxim HQ Bifrost MCP Gateway";
        After = [ "sops-nix.service" "graphical-session.target" ];
      };
      Service = {
        Environment = [
          "HOME=%h"
          "PATH=${lib.makeBinPath [ pkgs.bun ]}"
          "BIFROST_CONFIG_DIR=%h/.config/bifrost"
          "BIFROST_LOG_LEVEL=info"
          "BIFROST_CORS_ENABLED=true"
          "BIFROST_ALLOWED_ORIGINS=http://localhost:*"
        ];
        EnvironmentFile = "%h/.config/bifrost/.env";
        ExecStart = "${pkgs.bun}/bin/bunx @maximhq/bifrost --port 8765";
        WorkingDirectory = "%h/.config/bifrost";
        Restart = "on-failure";
        RestartSec = "5s";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    home.activation.bifrostConfig = lib.hm.dag.entryAfter [ "sops-nix" ] ''
      systemctl --user try-restart bifrost.service 2>/dev/null || true
    '';
  };
}
