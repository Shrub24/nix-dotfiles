_: {
  flake.modules.homeManager.grist =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.grist;
      webServices = (import ../../lib/web-services.nix { inherit lib; }).services;
      ociImages = import ../../policy/oci-images.nix;

      gristEnvArgs = [
        "-e GRIST_IN_SERVICE=true"
        "-e GRIST_FORCE_LOGIN=true"
        "-e GRIST_TELEMETRY_LEVEL=off"
        "-e GRIST_ALLOW_AUTOMATIC_VERSION_CHECKING=false"
        "-e GRIST_DEFAULT_EMAIL=${lib.escapeShellArg cfg.administratorEmail}"
        "-e GRIST_SINGLE_ORG=${lib.escapeShellArg cfg.organizationSlug}"
        "-e GRIST_MCP_ENABLED=true"
      ]
      ++ lib.optional (cfg.sandboxFlavor != null) "-e GRIST_SANDBOX_FLAVOR=${cfg.sandboxFlavor}";
    in
    {
      options.programs.grist = {
        enable = lib.mkEnableOption "Grist local spreadsheet database";

        port = lib.mkOption {
          type = lib.types.port;
          default = webServices.grist.port;
          description = "Loopback HTTP port for the Grist server.";
        };

        administratorEmail = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Initial administrator email (GRIST_DEFAULT_EMAIL).";
        };

        organizationSlug = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Single organization slug (GRIST_SINGLE_ORG).";
        };

        sandboxFlavor = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum [ "gvisor" ]);
          default = "gvisor";
          description = ''
            Formula sandbox flavor. "gvisor" sets GRIST_SANDBOX_FLAVOR=gvisor.
            Set to null to omit the variable and use Grist's built-in sandbox.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.administratorEmail != "" && cfg.organizationSlug != "";
            message = "programs.grist: administratorEmail and organizationSlug must be non-empty when enable = true";
          }
        ];

        systemd.user = {
          tmpfiles.rules = [
            "d %h/.local/share/grist 0700 - - -"
          ];

          services.grist = {
            Unit = {
              Description = "Grist local spreadsheet database";
              After = [
                "sops-nix.service"
                "network-online.target"
              ];
              Wants = [ "network-online.target" ];
              StartLimitBurst = 3;
              StartLimitIntervalSec = 120;
              X-Restart-Triggers = [ config.sops.templates."grist.env".path ];
              X-SwitchMethod = "restart";
            };

            Service = {
              Type = "simple";
              ExecStartPre = "${pkgs.podman}/bin/podman pull --quiet ${ociImages.grist}";
              ExecStart = ''
                ${pkgs.podman}/bin/podman run --rm --replace --name grist \
                  -p 127.0.0.1:${toString cfg.port}:8484 \
                  -v %h/.local/share/grist:/persist \
                  --env-file ${config.sops.templates."grist.env".path} \
                  ${lib.concatStringsSep " \\\n    " gristEnvArgs} \
                  ${ociImages.grist}
              '';
              ExecStop = "${pkgs.podman}/bin/podman stop grist";
              TimeoutStartSec = 600;
              Restart = "on-failure";
              RestartSec = "10s";
              StandardOutput = "journal";
              StandardError = "journal";
            };

            Install = {
              WantedBy = [ "default.target" ];
            };
          };
        };
      };
    }

  ;
}
