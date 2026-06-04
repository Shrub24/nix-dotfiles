{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.bifrost;
  bifrostGenerated = import ./generated.nix { inherit lib; };
  bifrostConfigJson = builtins.toJSON bifrostGenerated.bifrostConfig;
in
{
  options.programs.bifrost = {
    enable = lib.mkEnableOption "bifrost MCP gateway";
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."bifrost/config.json".text = bifrostConfigJson;

    systemd.user.services.bifrost = {
      Unit = {
        Description = "Maxim HQ Bifrost MCP Gateway";
        After = [
          "sops-nix.service"
          "graphical-session.target"
        ];
        X-Restart-Triggers = [ (builtins.hashString "sha256" bifrostConfigJson) ];
        X-SwitchMethod = "restart";
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
        ExecStartPre = "${pkgs.coreutils}/bin/rm -f %h/.config/bifrost/config.db";
        ExecStart = "${pkgs.bun}/bin/bunx @maximhq/bifrost --port 8765";
        WorkingDirectory = "%h/.config/bifrost";
        KillSignal = "SIGKILL";
        Restart = "on-failure";
        RestartSec = "5s";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
