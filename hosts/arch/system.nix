{ ... }:
{
  imports = [ ../../modules/system ];

  nixpkgs.hostPlatform = "x86_64-linux";
  system-manager.allowAnyDistro = true;

}
