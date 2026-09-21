{
  inputs,
  ...
}:
let
  # Evaluated once at the flake-parts level; `.wrap` is applied per system below.
  # Mirrors the upstream template's `wrappers.neovim.wrap { inherit pkgs; }`.
  wrapper = inputs.wrappers.lib.evalModule (import ./_wrapper.nix);
in
{
  # Aspect `nvim`: the nix-wrapped editor, on PATH as nvim-nix until the port
  # replaces the pacman nvim. Enable by adding "nvim" to hmAspects in
  # modules/hosts/arch.nix.
  flake.modules.homeManager.nvim =
    { pkgs, ... }:
    {
      home.packages = [ (wrapper.config.wrap { inherit pkgs; }) ];
    };
}
