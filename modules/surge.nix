_: {
  # Not surge's own flake module: it installs a self-overlay and writes its unit
  # outside the store. User-scoped: the daemon owns the files the user opens.
  flake.modules.homeManager.surge =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = [ pkgs.surge-downloader ];

      systemd.user.services.surge = {
        Unit = {
          Description = "Surge download manager server";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };

        Service = {
          # 1700 is what the browser extension expects.
          ExecStart = "${lib.getExe pkgs.surge-downloader} server start --port 1700 --output ${config.home.homeDirectory}/Downloads";
          Restart = "on-failure";
          RestartSec = "5s";
        };

        Install.WantedBy = [ "default.target" ];
      };
    };
}
