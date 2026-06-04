{ lib }:

let
  aliases = import ./aliases.nix;

  mkCelExpression = matches: lib.concatStringsSep " || " (map (model: "model == '${model}'") matches);

  routingRules = lib.mapAttrsToList (
    id: spec:
    {
      inherit id;
      name = id;
      priority = spec.priority;
      scope = "global";
      cel_expression = mkCelExpression spec.matches;
      targets = spec.targets;
    }
    // lib.optionalAttrs (spec ? fallbacks && spec.fallbacks != [ ]) {
      fallbacks = spec.fallbacks;
    }
  ) aliases;

  mkOpencodeModel = model: {
    name = model.name;
    limit = {
      context = model.context;
      output = model.output;
    };
    modalities = {
      input = model.inputModalities;
      output = model.outputModalities;
    };
  };

  opencodeModels = lib.foldl' (
    acc: spec: acc // lib.mapAttrs (_: mkOpencodeModel) spec.opencodeModels
  ) { } (builtins.attrValues aliases);

  bifrostConfig = {
    "$schema" = "https://www.getbifrost.ai/schema";
    client = {
      drop_excess_requests = true;
      enforce_auth_on_inference = false;
    };
    auth_config = {
      is_enabled = true;
      disable_auth_on_inference = true;
    };
    config_store = {
      enabled = true;
      type = "sqlite";
      config = {
        path = "./config.db";
      };
    };
    providers = {
      gemini = {
        keys = [
          {
            name = "gemini-primary";
            value = "env.GEMINI_API_KEY";
            weight = 1;
            models = [ ];
          }
        ];
      };
      deepseek = {
        custom_provider_config = {
          base_provider_type = "openai";
          allowed_requests = {
            list_models = true;
            chat_completion = true;
            chat_completion_stream = true;
          };
        };
        network_config = {
          base_url = "https://api.deepseek.com";
        };
        keys = [
          {
            name = "deepseek-primary";
            value = "env.DEEPSEEK_API_KEY";
            weight = 1;
            models = [ "*" ];
          }
        ];
      };
      opencode_go = {
        custom_provider_config = {
          base_provider_type = "openai";
          allowed_requests = {
            list_models = true;
            chat_completion = true;
            chat_completion_stream = true;
          };
        };
        network_config = {
          base_url = "https://opencode.ai/zen/go";
        };
        keys = [
          {
            name = "opencode-go-primary";
            value = "env.OPENCODE_API_KEY";
            weight = 1;
            models = [ "*" ];
          }
        ];
      };
      crof = {
        custom_provider_config = {
          base_provider_type = "openai";
          allowed_requests = {
            list_models = true;
            chat_completion = true;
            chat_completion_stream = true;
          };
        };
        network_config = {
          base_url = "https://crof.ai";
        };
        keys = [
          {
            name = "crofai-primary";
            value = "env.CROFAI_API_KEY";
            weight = 1;
            models = [ "*" ];
          }
        ];
      };
      openrouter = {
        keys = [
          {
            name = "openrouter-primary";
            value = "env.OPENROUTER_API_KEY";
            weight = 1;
            models = [
              "qwen/qwen3-embedding-8b"
              "xiaomi/mimo-v2.5-pro"
              "moonshotai/kimi-k2.6:free"
              "xiaomi/mimo-v2.5"
            ];
          }
        ];
      };
    };
    governance = {
      routing_rules = routingRules;
    };
  };
in
{
  inherit
    aliases
    bifrostConfig
    opencodeModels
    routingRules
    ;

  opencodeExtraConfig = {
    "$schema" = "https://opencode.ai/config.json";
    provider = {
      bifrost = {
        npm = "@ai-sdk/openai-compatible";
        name = "Bifrost";
        options = {
          baseURL = "http://localhost:8765/v1";
        };
        models = opencodeModels;
      };
    };
  };
}
