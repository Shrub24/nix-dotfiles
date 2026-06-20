{ pkgs, ... }:
{
  imports = [
    ./languages.nix
    ./mise.nix
    ./navi.nix
    ./lazyjournal.nix
  ];

  home.packages = with pkgs; [
    posting
    isd
  ];
}
