{ pkgs, ... }:
{
  # uwsm publishes the session entry; a hand-rolled niri.desktop would sort
  # before it and win the default.
  programs.uwsm.waylandCompositors.niri = {
    prettyName = "Niri";
    comment = "A scrollable-tiling Wayland compositor";
    binPath = "${pkgs.niri}/bin/niri";
  };
}
