{
  config,
  ...
}: let
  # Service topology read at the flake-parts level; closed over by the HM module.
  dbHost = config.topology.services.database.host;
in {
  flake.modules.homeManager.litellm = import ./_hm.nix { inherit dbHost; };
}
