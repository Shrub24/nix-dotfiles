{ inputs, ... }:
{
  flake.modules.nixos.monique =
    { ... }:
    {
      # Upstream nixosModules.default pins programs.monique.package to the flake
      # package via mkDefault; just import + enable.
      imports = [ inputs.monique.nixosModules.default ];
      programs.monique.enable = true;
    };

  flake.modules.homeManager.monique =
    {
      config,
      lib,
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
