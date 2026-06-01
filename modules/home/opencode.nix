{
  config,
  lib,
  appsDir,
  ...
}:

let
  bifrostGenerated = import ./agents/bifrost/generated.nix { inherit lib; };
in
{
  home.file.".config/opencode".source =
    config.lib.file.mkOutOfStoreSymlink "${toString appsDir}/opencode";
  home.file.".config/opencode-bifrost.json".text = builtins.toJSON bifrostGenerated.opencodeExtraConfig;
  home.file.".agents".source =
    config.lib.file.mkOutOfStoreSymlink "${toString appsDir}/agents";

  home.sessionVariables.OPENCODE_CONFIG = "${config.home.homeDirectory}/.config/opencode-bifrost.json";
}
