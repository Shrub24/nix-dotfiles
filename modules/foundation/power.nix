_: {
  flake.modules.nixos.power = _: {
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;
    services.acpid.enable = true;
  };
}
