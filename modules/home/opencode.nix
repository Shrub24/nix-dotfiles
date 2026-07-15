{
  config,
  lib,
  appsDir,
  ...
}:

let
  litellmGenerated = (import ./agents/litellm/generated.nix) {
    inherit lib;
    headroomEnable = config.programs.litellm.headroom.enable;
    headroomPort = config.programs.litellm.headroomPort;
  };
in
{
  home.file.".config/opencode".source =
    config.lib.file.mkOutOfStoreSymlink "${toString appsDir}/opencode";
  home.file.".config/opencode-litellm.json".text =
    builtins.toJSON litellmGenerated.opencodeExtraConfig;
  home.file.".agents".source = config.lib.file.mkOutOfStoreSymlink "${toString appsDir}/agents";

  home.sessionVariables.OPENCODE_CONFIG = "${config.home.homeDirectory}/.config/opencode-litellm.json";
}
