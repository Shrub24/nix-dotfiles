_: {
  # Host composition layer: literal system double for the Arch host (system-manager
  # scope has no `pkgs.stdenv`).
  nixpkgs.hostPlatform = "x86_64-linux";
  system-manager.allowAnyDistro = true;
}
