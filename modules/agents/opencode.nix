_: {
  flake.modules.homeManager.opencode =
    {
      config,
      lib,
      hostFacts,
      ...
    }:

    let
      litellmGenerated = (import ./litellm/_generated.nix) {
        inherit lib;
        headroomEnable = config.programs.litellm.headroom.enable;
        headroomPort = config.programs.litellm.headroomPort;
      };
    in
    {
      home = {
        file = {
          ".config/opencode".source = config.lib.file.mkOutOfStoreSymlink "${hostFacts.appsDir}/opencode";
          ".config/opencode-litellm.json".text = builtins.toJSON litellmGenerated.opencodeExtraConfig;
          ".agents".source = config.lib.file.mkOutOfStoreSymlink "${hostFacts.appsDir}/agents";
        };

        sessionVariables.OPENCODE_CONFIG = "${config.home.homeDirectory}/.config/opencode-litellm.json";
      };
    }

  ;
}
