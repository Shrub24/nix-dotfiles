_: {
  flake.modules.homeManager.brave =
    { pkgs, ... }:
    {
      # No home-manager `programs.brave` module exists; install the package so
      # ~/.config/BraveSoftware stays fully imperative and untouched.
      home.packages = [ pkgs.brave ];
    };
}
