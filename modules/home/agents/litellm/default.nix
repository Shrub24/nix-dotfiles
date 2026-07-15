{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.litellm;
  litellmGenerated = (import ./generated.nix) {
    inherit lib;
    headroomEnable = cfg.headroom.enable;
    headroomPort = cfg.headroomPort;
  };
  yamlFormat = pkgs.formats.yaml { };
  litellmConfigFile = yamlFormat.generate "litellm-config.yaml" litellmGenerated.litellmConfig;

  webServices = (import ../../../../lib/web-services.nix { inherit lib pkgs; }).services;

  ociImages = import ../../../../policy/oci-images.nix;
  ociImage = pkgs.litellm-oci;
in
{
  options.programs.litellm = {
    enable = lib.mkEnableOption "LiteLLM gateway";

    headroom.enable = lib.mkEnableOption "Headroom sidecar (context compression guardrail)";

    database.enable = lib.mkEnableOption "PostgreSQL database backend (admin UI, spend tracking, virtual keys)";

    port = lib.mkOption {
      type = lib.types.port;
      default = webServices.litellm.port;
      description = "HTTP port for the LiteLLM gateway.";
    };

    headroomPort = lib.mkOption {
      type = lib.types.port;
      default = 8787;
      description = "HTTP port for the Headroom sidecar.";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."litellm/config.yaml".source = litellmConfigFile;

    systemd.user.tmpfiles.rules = lib.mkIf cfg.headroom.enable [
      "d %h/.local/share/headroom 0755 - - -"
    ];

    # ── Headroom sidecar ─────────────────────────────────────────────
    systemd.user.services.headroom = lib.mkIf cfg.headroom.enable {
      Unit = {
        Description = "Headroom context compression sidecar";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.podman}/bin/podman run --rm --network host \
            --name headroom \
            -v %h/.local/share/headroom:/home/headroom/.headroom \
            -e HEADROOM_TELEMETRY=off \
            ${ociImages.headroom-code} \
            --host 127.0.0.1 --port ${toString cfg.headroomPort} --code-aware
        '';
        ExecStop = "${pkgs.podman}/bin/podman stop headroom";
        Restart = "on-failure";
        RestartSec = "5s";
        StandardOutput = "journal";
        StandardError = "journal";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    systemd.user.services.litellm = {
      Unit = {
        Description = "LiteLLM local gateway";
        After = [
          "sops-nix.service"
          "network-online.target"
          "podman.service"
        ]
        ++ lib.optionals cfg.headroom.enable [ "headroom.service" ];
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
        ExecStartPre = "${pkgs.podman}/bin/podman load -i ${ociImage}";
        ExecStart = ''
          ${pkgs.podman}/bin/podman run --rm --network host \
            --name litellm \
            -v %h/.config/litellm/config.yaml:/app/config.yaml:ro \
            --env-file ${config.sops.templates."litellm.env".path} \
            -e LITELLM_PORT=${toString cfg.port} \
            localhost/litellm-patched:latest
        '';
        ExecStop = "${pkgs.podman}/bin/podman stop litellm";
        TimeoutStartSec = 600;
        Restart = "on-failure";
        RestartSec = "5s";
        StandardOutput = "journal";
        StandardError = "journal";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    home.file.".local/bin/headroom" = lib.mkIf cfg.headroom.enable {
      executable = true;
      text = ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        if ! ${pkgs.podman}/bin/podman inspect --format '{{.State.Running}}' headroom 2>/dev/null | grep -q true; then
          echo "headroom: container is not running." >&2
          echo "Start it with: systemctl --user start headroom.service" >&2
          exit 1
        fi
        exec ${pkgs.podman}/bin/podman exec headroom headroom "$@"
      '';
    };

    home.file.".local/bin/litellm-sync-posting".executable = true;
    home.file.".local/bin/litellm-sync-posting".text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      OPENAPI_PATH="$(mktemp).json"
      ${pkgs.curl}/bin/curl -sf http://127.0.0.1:${toString cfg.port}/openapi.json > "$OPENAPI_PATH"
      ${pkgs.posting}/bin/posting import "$OPENAPI_PATH" \
        -o "$HOME/.local/share/posting/litellm.json" \
        -t openapi
      echo "Collection synced."
    '';

    home.activation.litellmConfig = lib.hm.dag.entryAfter [ "sops-nix" ] ''
      systemctl --user try-restart litellm.service 2>/dev/null || true
      # sync posting collection after service is ready
      sleep 1
      "$HOME/.local/bin/litellm-sync-posting" 2>/dev/null || true
    '';
  };
}
