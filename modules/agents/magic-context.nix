{ inputs, ... }: {
  flake.modules.homeManager.magic-context =
    {
      config,
      pkgs,
      ...
    }:

    {
      # Shared CortexKit config: Pi and OpenCode read the same file. The
      # runtime only reads it and the doctor CLI writes it only when absent,
      # so a store symlink is safe here. The Pi package itself is listed in
      # the pi aspect's `packages`.
      home.file.".config/cortexkit/magic-context.jsonc".source =
        (pkgs.formats.json { }).generate "magic-context.json"
          {
            "$schema" =
              "https://raw.githubusercontent.com/cortexkit/magic-context/master/assets/magic-context.schema.json";
            historian = {
              opencode = {
                model = "opencode-omniroute/coder-high";
                fallback_models = [
                  "opencode-omniroute/budget"
                ];
              };
              pi = {
                model = "anthropic/claude-haiku-5-5";
                fallback_models = [
                  "omniroute/neural/deepseek-v4.1-flash"
                  "openai-codex/gpt-6-luna"
                ];
                thinking_level = "low";
              };
            };
            dreamer.disable = true;
            memory.enabled = true;
            embedding = {
              provider = "openai-compatible";
              model = "voyage-4";
              endpoint = "https://api.voyageai.com/v1";
              api_key = "{env:VOYAGE_API_KEY}";
              input_type = "document";
              query_input_type = "query";
            };
            cache_ttl = {
              default = "never";
            };
            toast_duration_ms = 500;
            execute_threshold_tokens.default = 250000;
            smart_drops = true;

            profiles.subagent.memory.read_only = true;
            profiles.subagent.pi.subagent_prompt = true;
            pi.cache_ttl = "never";
            # Children are spawned as the bare pi-bolt binary with
            # --no-extensions, so this is their explicit extension set. Providers
            # first — the historian resolves its own models inside this child.
            # Compiled extensions use their builtin: name; runtime ones use
            # their installed path.
            pi.subagent_extensions = [
              "builtin:omniroute"
              "builtin:anthropic-auth"
              "builtin:tool-repair"
              "${inputs.pi-extensions}/pi-native-router"
              "${config.home.homeDirectory}/.pi/agent/npm/node_modules/pi-commandcode-provider"
              "builtin:todo"
              "${config.home.homeDirectory}/.pi/agent/npm/node_modules/opensec-pi-fff"
            ];
          };
    };
}
