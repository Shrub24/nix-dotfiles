_: {
  # Declared here rather than via surge's own flake module, which installs a
  # self-overlay and writes its unit outside the store. User-scoped because the
  # daemon owns the files the user then opens.
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
          # Output dir defaults to the working directory; 1700 is what the
          # browser extension expects.
          ExecStart = "${lib.getExe pkgs.surge-downloader} server start --port 1700 --output ${config.home.homeDirectory}/Downloads";
          Restart = "on-failure";
          RestartSec = "5s";
        };

        Install.WantedBy = [ "default.target" ];
      };
    };
}
