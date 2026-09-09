{
  config,
  ...
}:
let
  remoteHosts = config.topology.hosts.arch.remoteHosts;
in
{
  flake.modules.homeManager.lazyjournal =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.lazyjournal;
    in
    {
      options.programs.lazyjournal = {
        enable = lib.mkEnableOption "lazyjournal — TUI for journald, file, Docker and remote SSH logs";

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.lazyjournal;
          defaultText = lib.literalExpression "pkgs.lazyjournal";
          description = "The lazyjournal package to install.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        xdg.configFile."lazyjournal/config.yml".text = lib.generators.toYAML { } {
          ssh = {
            hosts = remoteHosts;
          };
        };
      };
    }

  ;
}
