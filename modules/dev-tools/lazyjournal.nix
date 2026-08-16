_: {
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

        sshHosts = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [
            "do-admin-1"
            "oci-melb-1"
          ];
          description = ''
            SSH connection strings for remote log access. Each entry is passed
            verbatim to ssh(1), so bare host aliases resolve via the user's
            SSH config. The form `user@host -p 2222` is also accepted.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        xdg.configFile."lazyjournal/config.yml".text = lib.generators.toYAML { } {
          ssh = {
            hosts = cfg.sshHosts;
          };
        };
      };
    }

  ;
}
