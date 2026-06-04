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
      default = "http://oci-melb-1:5751";
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

    home.activation.restartNiks3AutoUpload = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
      $DRY_RUN_CMD systemctl --user restart niks3-auto-upload.socket || true
    '';
  };
}
