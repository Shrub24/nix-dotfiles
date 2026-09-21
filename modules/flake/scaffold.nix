{ inputs, ... }:
{
  # Declare the `flake.modules` option (class-grouped published modules) from
  # flake-parts' extra `modules` flake-module before aspects are defined.
  imports = [ inputs.flake-parts.flakeModules.modules ];
}
