_: {
  flake.modules.homeManager.syncthing =
    { ... }:
    {
      services.syncthing.enable = true;
    };

  flake.modules.nixos.syncthing = { ... }: {
    services.syncthing = {
      enable = true;
      user = "saurabhj";
      dataDir = "/home/saurabhj";
      openDefaultPorts = true;
      overrideDevices = false;
      overrideFolders = false;
    };
  };
}
