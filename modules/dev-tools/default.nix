{ inputs, ... }:
{
  flake-file.inputs.fsel = {
    url = "github:Mjoyufull/fsel";
    # fsel's nixpkgs pin is shared; its own naersk is not this repository's.
    inputs.naersk.autoFollow = false;
  };

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
