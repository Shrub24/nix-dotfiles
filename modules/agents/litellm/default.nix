{
  config,
  ...
}:
let
  dbHost = config.topology.services.database.host;
in
{
  flake.modules.homeManager.litellm = import ./_hm.nix { inherit dbHost; };
}
