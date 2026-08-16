_: {
  flake.modules.homeManager.monique =
    {
      config,
      lib,
      inputs,
      pkgs,
      ...
    }:
    let
      moniquePackage = inputs.monique.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      # force: unmanaged regular file; Monique replaces Shikane as the hotplug daemon.
      xdg.configFile."autostart/shikane.desktop" = {
        force = true;
        text = ''
          [Desktop Entry]
          Hidden=true
        '';
      };

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

      # Monique's mutable monitors.kdl is the single runtime monitor authority; the
      # include applies only when the niri aspect is selected and enabled.
      wayland.windowManager.niri.extraConfig =
        lib.mkIf (config ? wayland.windowManager.niri && config.wayland.windowManager.niri.enable)
          ''
            include optional=true "monitors.kdl"
          '';

      home.packages = [
        moniquePackage
      ];
    }

  ;
}
