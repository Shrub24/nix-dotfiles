_: {
  flake.modules.homeManager.brave-origin =
    { pkgs, ... }:
    {
      # No programs.brave module; package install keeps ~/.config/BraveSoftware imperative.
      home.packages = [ pkgs.brave-origin ];
    };
}
