{ config, lib, inputs, pkgs, ... }:

let
  system = "x86_64-linux";
  cfg = config.programs.bifrost;
in
{
  options.programs.bifrost = {
    enable = lib.mkEnableOption "bifrost MCP gateway";
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."bifrost/config.json.tpl".text = builtins.readFile ./config.json;

    systemd.user.services.bifrost = {
      Unit = {
        Description = "Maxim HQ Bifrost MCP Gateway";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Environment = [
          "HOME=%h"
          "BIFROST_CONFIG_DIR=%h/.config/bifrost"
          "BIFROST_LOG_LEVEL=info"
          "BIFROST_CORS_ENABLED=true"
          "BIFROST_ALLOWED_ORIGINS=http://localhost:*"
          "JDOCMUNCH_SUMMARIZER_PROVIDER=google"
          "JCODEMUNCH_SUMMARIZER_PROVIDER=google"
          "GOOGLE_EMBED_MODEL=gemini-embedding-002"
          "UV_PATH=%h/.local/bin/uv"
        ];
        ExecStart = "/usr/bin/zsh -lc 'pnpx @maximhq/bifrost --port 8765'";
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

    home.activation.bifrost = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ~/.config/bifrost
      if [ -f ~/.config/bifrost/config.json.tpl ]; then
        envsubst < ~/.config/bifrost/config.json.tpl | sed 's/"__SCHEMA__"/"$schema"/' > ~/.config/bifrost/config.json
      fi
      systemctl --user daemon-reload 2>/dev/null || true
      systemctl --user enable --now bifrost.service 2>/dev/null || true
      systemctl --user restart bifrost.service 2>/dev/null || true
    '';
  };
}
