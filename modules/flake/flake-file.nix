{ inputs, ... }:
{
  # flake-file generates flake.nix from the input declarations in this tree:
  # the core module supplies the flake-file.* options, the write-flake app and
  # checks.check-flake-file. Its auto-follow module is deliberately not
  # imported: auto-follow rewrites nested `follows` through flake-edit and
  # discards any `follows` a module declares, which would leave the generated
  # flake.nix holding state the tree cannot reproduce. Every nested follows is
  # declared where its input is declared instead, so the file stays a pure
  # function of the tree. The dendritic entry point is declared rather than
  # imported from flake-file's preset, so nothing sets a default url or follows
  # that this repository would have to override back out.
  imports = [
    inputs.flake-file.flakeModules.default
  ];

  systems = [ "x86_64-linux" ];

  flake-file = {
    description = "saurabhj's Nix configuration — dendritic home-manager";
    outputs = "dendritic";
  };
}
