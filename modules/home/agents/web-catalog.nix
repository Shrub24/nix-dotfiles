{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.webCatalog;
  homepage = import ../../../lib/web-services.nix { inherit lib pkgs; };
  catalogDir = pkgs.writeTextDir "homelab-services.json" (
    builtins.toJSON (homepage.toCatalogJSON homepage.catalog)
  );
in
{
  options.programs.webCatalog = {
    enable = lib.mkEnableOption "web service catalog HTTP server";

    port = lib.mkOption {
      type = lib.types.port;
      default = homepage.services.web-catalog.port;
      description = "HTTP port for the catalog server.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.web-catalog = {
      Unit = {
        Description = "Web Service Catalog HTTP Server";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "exec";
        ExecStart = "${pkgs.python3}/bin/python3 -m http.server ${toString cfg.port} --bind 0.0.0.0 --directory ${catalogDir}";
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
