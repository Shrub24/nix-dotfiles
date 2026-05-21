{ pkgs, ... }: {
  imports = [
    ./languages.nix
    ./mise.nix
    ./navi.nix
  ];

  home.packages = with pkgs; [
    sysz
  ];
}
