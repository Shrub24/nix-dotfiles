{
  config,
  inputs,
  ...
}:
let
  # Service topology read at the flake-parts level, closed over by the HM and
  # NixOS modules.
  niks3ServerUrl = config.topology.services.niks3.host;
in
{
  flake.modules.nixos.niks3 =
    { config, lib, ... }:
    {
      # Closure upload to a remote cache. nix-fleet owns the mechanism — the
      # upstream post-build-hook module, the sops secret, the socket path; this
      # binds the server URL and where the token lives.
      imports = [
        inputs.nix-fleet.modules.nixos.niks3-publisher
        inputs.sops-nix.nixosModules.sops
      ];

      services.niks3-publisher = {
        serverUrl = niks3ServerUrl;
        secretFiles.apiToken = ../secrets/niks3-secrets.yaml;
        secretKeys.apiToken = "niks3_auth_token";
      };

      # Completes nix-fleet's declaration: a rotated token must not keep being
      # served by an already-running uploader. Guarded on the same gate the
      # fleet uses, so this never declares the secret on its own.
      sops.secrets.niks3_api_token =
        lib.mkIf (config.services.niks3-publisher.secretFiles.apiToken != null)
          {
            restartUnits = [ "niks3-auto-upload.service" ];
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

      authTokenPath = "${config.home.homeDirectory}/.config/niks3/auth-token";
      # `%t` is the user's runtime directory; the root-side post-build hook in
      # modules/nix.nix resolves the same socket to /run/user/<uid>.
      socketPath = "%t/niks3-upload-to-cache.sock";
      stateDir = "${config.home.homeDirectory}/.local/state/niks3-hook";
    in
    {
      options.programs.niks3.enableAutoUploadService = lib.mkEnableOption "niks3 user-side auto-upload daemon";

      config = lib.mkIf cfg.enableAutoUploadService {
        sops = {
          secrets."NIKS3_AUTH_TOKEN" = {
            sopsFile = ../secrets/niks3-secrets.yaml;
            format = "yaml";
            key = "niks3_auth_token";
          };

          templates."niks3-auth-token" = {
            path = authTokenPath;
            content = config.sops.placeholder.NIKS3_AUTH_TOKEN;
          };
        };

        home.packages = [ pkgs.niks3 ];

        systemd.user.sockets.niks3-auto-upload = {
          Unit = {
            Description = "niks3 upload queue socket";
          };

          Socket = {
            ListenStream = socketPath;
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
            ExecStartPre = "${lib.getExe' pkgs.coreutils "mkdir"} -p ${stateDir}";
            ExecStart = "${lib.getExe' pkgs.niks3 "niks3-hook"} serve --server-url ${lib.escapeShellArg niks3ServerUrl} --auth-token-path ${lib.escapeShellArg authTokenPath} --socket ${lib.escapeShellArg socketPath} --db-path ${lib.escapeShellArg "${stateDir}/upload-queue.db"}";
            Restart = "on-failure";
            RestartSec = "5s";
          };
        };
      };
    }

  ;
}
