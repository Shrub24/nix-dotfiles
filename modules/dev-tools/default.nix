_: {
  flake.modules.homeManager.dev-tools =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        zotero
        posting
        isd
        crun
        skopeo
        fsel
      ];
    };
}
