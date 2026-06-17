{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.litellm;
  litellmGenerated = (import ./generated.nix) { inherit lib; };
  yamlFormat = pkgs.formats.yaml { };
  litellmConfigFile = yamlFormat.generate "litellm-config.yaml" litellmGenerated.litellmConfig;
in
{
  options.programs.litellm = {
    enable = lib.mkEnableOption "LiteLLM gateway";

    headroom.enable = lib.mkEnableOption "global Headroom callback middleware for LiteLLM";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8765;
      description = "HTTP port for the LiteLLM gateway.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = if cfg.headroom.enable then pkgs."litellm-with-headroom" else pkgs.litellm;
      defaultText = lib.literalExpression ''if config.programs.litellm.headroom.enable then pkgs."litellm-with-headroom" else pkgs.litellm'';
      description = "LiteLLM package to run for the local gateway.";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."litellm/config.yaml".source = litellmConfigFile;

    systemd.user.services.litellm = {
      Unit = {
        Description = "LiteLLM local gateway";
        After = [
          "sops-nix.service"
          "network-online.target"
        ];
        Wants = [ "network-online.target" ];
        X-Restart-Triggers = [
          litellmConfigFile
          config.sops.templates."litellm.env".path
        ];
        X-SwitchMethod = "restart";
      };

      Service = {
        Type = "simple";
        Environment = [ "HOME=%h" ];
        EnvironmentFile = [ config.sops.templates."litellm.env".path ];
        ExecStart = "${lib.getExe cfg.package} --config %h/.config/litellm/config.yaml --host 127.0.0.1 --port ${toString cfg.port}";
        WorkingDirectory = "%h/.config/litellm";
        Restart = "on-failure";
        RestartSec = "5s";
        StandardOutput = "journal";
        StandardError = "journal";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    home.activation.litellmConfig = lib.hm.dag.entryAfter [ "sops-nix" ] ''
      systemctl --user try-restart litellm.service 2>/dev/null || true
    '';
  };
}
