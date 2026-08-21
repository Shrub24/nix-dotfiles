{ primaryUser }: { ... }: {
  imports = [ (import ./_hardware.nix { inherit primaryUser; }) ];
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "26.11";
  networking.hostName = "shrub";
  i18n.defaultLocale = "en_AU.UTF-8";
}
