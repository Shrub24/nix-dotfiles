{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    ./languages.nix
    ./mise.nix
    ./navi.nix
    ./lazyjournal.nix
  ];

  home.packages = with pkgs; [
    zotero
    posting
    isd
    crun
    jjui
    skopeo
    inputs.fsel.packages.${system}.default
  ];
}
