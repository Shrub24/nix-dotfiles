_: {
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
                model = "neuralwatt/deepseek-v4.1-flash";
                fallback_models = [
                  "anthropic/claude-haiku-5-5"
                  "openai-codex/gpt-6-luna"
                ];
                thinking_level = "low";
              };
            };
            dreamer = {
              opencode = {
                model = "opencode-omniroute/coder-high";
                fallback_models = [
                  "opencode-omniroute/budget"
                ];
              };
              pi = {
                # Dream tasks are background work on a schedule, so the flex tier's
                # spare-capacity queueing costs nothing they care about.
                model = "neuralwatt/deepseek-v4.1-flash-flex";
                fallback_models = [
                  "anthropic/claude-haiku-5-5"
                  "openai-codex/gpt-6-luna"
                ];
                thinking_level = "low";
              };
            };
            memory.enabled = true;
            embedding = {
              provider = "openai-compatible";
              model = "voyage-4";
              endpoint = "https://api.voyageai.com/v1";
              api_key = "{env:VOYAGE_API_KEY}";
              input_type = "document";
              query_input_type = "query";
            };
            # 250k is the working baseline and 300k the larger Anthropic models. gpt-6.2-sol serves
            # 500k upstream, but this catalog entry declares 272k, so MC measures usage against that
            # and clamps anything above 90% of it. Unlisted models fall back to
            # execute_threshold_percentage (65%).
            execute_threshold_tokens = {
              "anthropic/claude-haiku-5-5" = 250000;
              "anthropic/claude-sonnet-5-5" = 300000;
              "anthropic/claude-opus-5-5" = 300000;
              "commandcode/deepseek/deepseek-v4.1-flash" = 250000;
              "openai-codex/gpt-6-luna" = 250000;
              "openai-codex/gpt-6.2-sol" = 250000;
              "openai-codex/gpt-6.2-astra" = 250000;
              "opencode-go/deepseek-v4.1-flash" = 250000;
              "opencode-go/glm-5.3" = 250000;
              "opencode-go/mimo-v2.6-flash" = 250000;
            };
            cache_ttl = {
              default = "never";
              "anthropic/claude-haiku-5-5" = "1h";
              "anthropic/claude-sonnet-5-5" = "1h";
              "anthropic/claude-opus-5-5" = "1h";
              "commandcode/deepseek/deepseek-v4.1-flash" = "3h";
              "openai-codex/gpt-6-luna" = "2h";
              "openai-codex/gpt-6.2-sol" = "2h";
              "openai-codex/gpt-6.2-astra" = "2h";
              "opencode-go/deepseek-v4.1-flash" = "3h";
              "opencode-go/glm-5.3" = "3h";
              "opencode-go/mimo-v2.6-flash" = "10m";
            };
            toast_duration_ms = 500;
            smart_drops = true;

            profiles.subagent.memory.read_only = true;
            profiles.subagent.pi.subagent_prompt = true;

            pi.subagent_extensions = [
              "builtin:neuralwatt"
              "builtin:anthropic-auth"
              "builtin:tool-repair"
              "builtin:todo"
              "${config.home.homeDirectory}/.pi/agent/npm/node_modules/opensec-pi-fff"
            ];
          };
    };
}
