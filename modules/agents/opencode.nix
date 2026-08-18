_: {
  flake.modules.homeManager.opencode =
    {
      config,
      lib,
      ...
    }:

    let
      litellmGenerated = (import ./litellm/_generated.nix) {
        inherit lib;
        headroomEnable = config.programs.litellm.headroom.enable;
        headroomPort = config.programs.litellm.headroomPort;
        port = config.programs.litellm.port;
      };
    in
    {
      home = {
        file = {
          ".config/opencode".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/apps/opencode";
          ".config/opencode-litellm.json".text = builtins.toJSON litellmGenerated.opencodeExtraConfig;
          ".agents".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/apps/agents";
        };

        sessionVariables.OPENCODE_CONFIG = "${config.home.homeDirectory}/.config/opencode-litellm.json";
      };
    }

  ;
}
