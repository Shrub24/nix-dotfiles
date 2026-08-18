{ inputs, ... }: {
  flake.modules.homeManager.dev-tools =
    { pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
      home.packages = with pkgs; [
        zotero
        posting
        isd
        crun
        jjui
        skopeo
        surge
        inputs.fsel.packages.${system}.default
      ];
    }

  ;
}
