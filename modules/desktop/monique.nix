{ inputs, ... }:
{
  flake-file.inputs.monique = {
    url = "github:ToRvaLDz/monique";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.monique = _: {
    imports = [ inputs.monique.nixosModules.default ];
    programs.monique.enable = true;
  };

  flake.modules.homeManager.monique =
    {
      pkgs,
      ...
    }:
    let
      moniquePackage = inputs.monique.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {

      systemd.user.services.moniqued = {
        Unit = {
          Description = "Monique daemon - Auto-apply monitor profiles on hotplug";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          Type = "simple";
          ExecStart = "${moniquePackage}/bin/moniqued";
          Restart = "on-failure";
          RestartSec = "5";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };

      home.packages = [
        moniquePackage
      ];
    }

  ;
}
