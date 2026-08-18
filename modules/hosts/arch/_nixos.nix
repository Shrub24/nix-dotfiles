{ ... }: {
  imports = [ ./_hardware.nix ];
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "26.11";
  networking.hostName = "arch";
  users.users.saurabhj = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
