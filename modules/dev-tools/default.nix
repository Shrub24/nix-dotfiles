{ inputs, ... }:
{
  flake.modules.homeManager.dev-tools =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        zotero
        posting
        isd
        crun
        skopeo
        inputs.fsel.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
