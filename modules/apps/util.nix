_: {
  flake.modules.homeManager.util-apps =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.meld
        pkgs.puddletag
        pkgs.czkawka
        pkgs.gparted
        pkgs.smartcat
        pkgs.matugen
        pkgs.wl-mirror
        pkgs.adw-gtk3
      ];
    };
}
