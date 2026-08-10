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
  headroomModelAliasMap = builtins.toJSON litellmGenerated.headroomModelAliasMap;
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

    # ── Headroom sidecar (OCI, no nixpkgs equivalent) ───────────────
    systemd.user.services.headroom = lib.mkIf cfg.headroom.enable {
      Unit = {
        Description = "Headroom context compression sidecar";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
        StartLimitBurst = 3;
        StartLimitIntervalSec = 120;
      };

      Service = {
        Type = "simple";
        CPUQuota = "200%";
        ExecStartPre = "${pkgs.podman}/bin/podman pull --quiet ${ociImages.headroom-code}";
        ExecStart = ''
          ${pkgs.podman}/bin/podman run --rm --replace --network host \
            --name headroom \
            --workdir /tmp/headroom-home \
            -v %h/.local/share/headroom:/tmp/headroom-home/.headroom \
            -e HOME=/tmp/headroom-home \
            -e HEADROOM_WORKSPACE_DIR=/tmp/headroom-home/.headroom \
            -e HEADROOM_CONFIG_DIR=/tmp/headroom-home/.headroom/config \
            -e HEADROOM_MODEL_ALIAS_MAP='${headroomModelAliasMap}' \
            -e HEADROOM_TELEMETRY=off \
            -e HEADROOM_SAVINGS_PROFILE=coding \
            ${ociImages.headroom-code} \
            --host 127.0.0.1 --port ${toString cfg.headroomPort} --code-aware \
            --compression-max-workers 2 --disable-kompress --disable-kompress-fallback \
            --no-rate-limit
        '';
        ExecStop = "${pkgs.podman}/bin/podman stop headroom";
        Restart = "on-failure";
        RestartSec = "10s";
        StandardOutput = "journal";
        StandardError = "journal";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # ── LiteLLM gateway (OCI with one-time image load) ─────────────
    systemd.user.services.litellm = {
      Unit = {
        Description = "LiteLLM local gateway";
        After = [
          "sops-nix.service"
          "network-online.target"
        ]
        ++ lib.optionals cfg.headroom.enable [ "headroom.service" ];
        Requires = lib.optionals cfg.headroom.enable [ "headroom.service" ];
        Wants = [ "network-online.target" ];
        StartLimitBurst = 3;
        StartLimitIntervalSec = 120;
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
        ExecStart = ''
          ${pkgs.podman}/bin/podman run --rm --replace --network host \
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

    # One-time image load at activation — avoids unpacking tarball on every restart
    home.activation.litellmImageLoad = lib.hm.dag.entryAfter [ "sops-nix" ] ''
      if ! ${pkgs.podman}/bin/podman image inspect localhost/litellm-patched:latest >/dev/null 2>&1; then
        ${pkgs.podman}/bin/podman load -i ${ociImage} >/dev/null 2>&1 || true
      fi
    '';

    home.file.".local/share/headroom/models.json" = lib.mkIf cfg.headroom.enable {
      text = builtins.toJSON litellmGenerated.headroomCatalog;
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
        exec ${pkgs.podman}/bin/podman exec headroom python3 -m headroom.cli "$@"
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
