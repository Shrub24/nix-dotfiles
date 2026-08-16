{ hostFacts, ... }:
{
  nixpkgs.hostPlatform = hostFacts.architecture;
  system-manager.allowAnyDistro = true;
}
