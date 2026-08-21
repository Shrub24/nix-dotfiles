{
  config,
  inputs,
  ...
}:
let
  # Service topology read at the flake-parts level (B6); closed over by the HM
  # and NixOS modules. niks3's serverUrl is a URL.
  niks3ServerUrl = config.topology.services.niks3.host;
in
{
  flake.modules.nixos.niks3 =
    { config, ... }:
    {
      # CLIENT-side auto-upload (post-build-hook) module: this host uploads to a
      # remote niks3 server; the server module (services.niks3) is not used here.
      imports = [
        inputs.niks3.nixosModules.niks3-auto-upload
        inputs.sops-nix.nixosModules.sops
      ];

      # Root-owned service secret (D5): consumed directly as the rendered path.
      sops.secrets.NIKS3_AUTH_TOKEN = {
        sopsFile = ../secrets/niks3-secrets.yaml;
        format = "yaml";
        key = "niks3_auth_token";
        mode = "0400";
        restartUnits = [ "niks3-auto-upload.service" ];
      };

      services.niks3-auto-upload = {
        enable = true;
        serverUrl = niks3ServerUrl;
        authTokenFile = config.sops.secrets.NIKS3_AUTH_TOKEN.path;
      };
    };

  flake.modules.homeManager.niks3 =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.niks3;
    in
    {
      options.programs.niks3 = {
        enableAutoUploadService = lib.mkEnableOption "niks3 user-side auto-upload daemon";

        serverUrl = lib.mkOption {
          type = lib.types.str;
          default = niks3ServerUrl;
          description = "niks3 cache server URL to upload to.";
        };

        authTokenPath = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/.config/niks3/auth-token";
          description = "Path to the niks3 auth token file.";
        };

        socketPath = lib.mkOption {
          type = lib.types.str;
          default = "%t/niks3-upload-to-cache.sock";
          description = "User-runtime socket path for the root post-build hook to send store paths to.";
        };

        stateDir = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/.local/state/niks3-hook";
          description = "Directory for the niks3 upload queue database.";
        };
      };

      config = lib.mkIf cfg.enableAutoUploadService {
        # Niks3 owns its auth token secret (own ciphertext file) + template.
        sops = {
          secrets."NIKS3_AUTH_TOKEN" = {
            sopsFile = ../secrets/niks3-secrets.yaml;
            format = "yaml";
            key = "niks3_auth_token";
          };

          templates."niks3-auth-token" = {
            path = "${config.home.homeDirectory}/.config/niks3/auth-token";
            content = config.sops.placeholder.NIKS3_AUTH_TOKEN;
          };
        };

        home.packages = [ pkgs.niks3-hook ];

        systemd.user.sockets.niks3-auto-upload = {
          Unit = {
            Description = "niks3 upload queue socket";
          };

          Socket = {
            ListenStream = cfg.socketPath;
            SocketMode = "0600";
            RemoveOnStop = true;
          };

          Install = {
            WantedBy = [ "sockets.target" ];
          };
        };

        systemd.user.services.niks3-auto-upload = {
          Unit = {
            Description = "niks3 upload queue";
            After = [ "sops-nix.service" ];
            Requires = [ "niks3-auto-upload.socket" ];
          };

          Service = {
            Type = "exec";
            Environment = "PATH=${lib.makeBinPath [ config.nix.package ]}";
            ExecStartPre = "${lib.getExe' pkgs.coreutils "mkdir"} -p ${cfg.stateDir}";
            ExecStart = "${lib.getExe' pkgs.niks3-hook "niks3-hook"} serve --server-url ${lib.escapeShellArg cfg.serverUrl} --auth-token-path ${lib.escapeShellArg cfg.authTokenPath} --socket ${lib.escapeShellArg cfg.socketPath} --db-path ${lib.escapeShellArg "${cfg.stateDir}/upload-queue.db"}";
            Restart = "on-failure";
            RestartSec = "5s";
          };
        };
      };
    }

  ;
}
