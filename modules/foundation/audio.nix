_: {
  flake.modules.nixos.audio = _: {
    services.pipewire = {
      enable = true;
      audio.enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
    security.rtkit.enable = true;
  };
}
