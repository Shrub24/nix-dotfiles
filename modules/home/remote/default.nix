{ pkgs, ... }:
{
  imports = [
    ./ssh.nix
    ./mosh.nix
    ./mutagen.nix
  ];
  home.packages = with pkgs; [
    sshs
  ];
}
