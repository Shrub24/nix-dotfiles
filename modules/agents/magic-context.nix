_: {
  flake.modules.homeManager.magic-context =
    { pkgs, ... }:

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
                model = "omniroute/neural/deepseek-v4.1-flash";
                fallback_models = [
                  "omniroute/neural/glm-5.3-flash"
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
              default = "30m";
              "openai-codex/*" = "10m";
              "anthropic/*" = "60m";
            };
            toast_duration_ms = 500;
            execute_threshold_tokens.default = 200000;
            smart_drops = true;
            todowrite.enabled = true;

            pi.subagent_extensions = [
              "npm/node_modules/pi-tool-repair/tool-repair.ts"
            ];
          };
    };
}
