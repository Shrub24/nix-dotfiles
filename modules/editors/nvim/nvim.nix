{
  inputs,
  ...
}:
let
  # Evaluated once at the flake-parts level; `.wrap` is applied per system below.
  wrapper = inputs.wrappers.lib.evalModule (import ./_wrapper.nix);
in
{
  flake-file.inputs.wrappers = {
    url = "github:nix-community/nix-wrapper-modules";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Aspect `nvim`: the nix-wrapped editor, installed as nvim.
  flake.modules.homeManager.nvim =
    { pkgs, ... }:
    {
      home.packages = [ (wrapper.config.wrap { inherit pkgs; }) ];
    };
}
