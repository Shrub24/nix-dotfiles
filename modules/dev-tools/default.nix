_: {
  flake.modules.homeManager.dev-tools =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        posting
        isd
        crun
        skopeo
        fsel
      ];
    };
}
