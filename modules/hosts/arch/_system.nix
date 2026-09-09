_: {
  # Literal system double: the system-manager scope has no `pkgs.stdenv`.
  nixpkgs.hostPlatform = "x86_64-linux";
  system-manager.allowAnyDistro = true;
}
