_: {
  flake.modules.nixos.audio = _: {
    services.pipewire = {
      enable = true;
      audio.enable = true;
      alsa.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
    security.rtkit.enable = true;

    # libpipewire-module-x11-bell holds an X11 connection to the lazy Xwayland and
    # calls exit() when it goes away, restarting PipeWire every few minutes. An
    # empty DISPLAY makes the module decline to load.
    systemd.user.services.pipewire.environment.DISPLAY = "";
  };
}
